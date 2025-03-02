# experiments/ai_misc/rag.rb
#
# See: https://gist.github.com/ahoward/3726b9339a62fbc82b1cd62bd0c1668f

require 'sqlite3'
require 'sqlite_vec'
require "sequel"
require "map"
require "ro"

require_relative 'utils'
require_relative 'path'

module Rag
  def dbsetup!
  #
    db = "./data/disco.sqlite"

    @vec0 = SQLite3::Database.new(db)
    @vec0.enable_load_extension(true)
    SqliteVec.load(@vec0)
    @vec0.enable_load_extension(false)

    #n = 1024
    @vec0.execute <<~__
      create virtual table if not exists rag using vec0(
        id integer primary key,

        embedding float[384],

        chunk_id integer,

        src text,
        subsrc text,
        author text,
        period text,
        published_at text,
        sentiment text
      );
    __

    @db = Sequel.sqlite(db, setup_regexp_function: true)

    unless @db.table_exists?(:chunks)
      @db.create_table :chunks do
        primary_key :id
        String :src
        String :key
        String :url
        String :raw
        String :tldr
      end
      @db.add_index :chunks, :key, :unique => true
    end

    unless @db.table_exists?(:facets)
      @db.create_table :facets do
        primary_key :id
        String :chunk_id
        String :key
        String :value
      end
      @db.add_index :facets, :key
      @db.add_index :facets, :value
    end

    @chunks = @db[:chunks]
    @facets = @db[:facets]
  end

  def chunk_ids_for_facets(facets = {})
    sql = proc{|s| Sequel.lit(s.to_s)}
    esc = proc{|s| s.to_s.inspect}

    ops = %w[ > < >= <= ]

    chunk_ids = []

    unless facets.empty?
      facets = Map.for(facets)

      facets.each do |key, value|
        q =
          if chunk_ids.size > 0
            @facets.where(chunk_id: chunk_ids)
          else
            @facets
          end

        q =
          if value.is_a?(Array) && value.size == 2 && ops.include?(value.first.to_s)
            op = value.shift.to_s
            value = value.shift.to_s
            q.where(sql["key = #{ esc[key] } AND value #{ op } #{ esc[value] }"])
          else
            q.where(key: key, value: value)
          end

        rows =
          q.select(:chunk_id).distinct

        chunk_ids =
          rows.map{|row| row.fetch(:chunk_id)}
      end
    end

    chunk_ids
  end

  def search_for(prompt:nil, tldr:nil, raw:nil, facets:nil)
    tldr ||= prompt
    raw ||= prompt

    unless tldr || raw || facets
      raise ArgumentError.new('empty search!')
    end

    [].tap do |lines|
      if tldr
        lines << "<TLDR>"
        lines << Utils.indent(tldr)
        lines << "</TLDR>"
        lines << "\n"
      end

      if facets
        lines << "<FACETS>"
        lines << Utils.indent(JSON.pretty_generate(facets))
        lines << "</FACETS>"
        lines << "\n"
     end

      if raw
        lines << "<RAW>"
        lines << Utils.indent(raw)
        lines << "</RAW>"
        lines << "\n"
      end
    end.join("\n\n")
  end

  def facets_for(facets)
    Map.for(facets).dup.tap do |facets|
      {
        :subreddit  => :subsrc,
        :subreddits => :subsrc,
        :keywords   => :keyword,
        :topics     => :topic,
        :themes     => :theme,
      }.each do |src, dst|
        if facets.has_key?(src)
          facets[dst] ||= facets.delete(src)
        end
      end
    end
  end

  def chunks_for(prompt, facets:{}, limit:16, rerank:'slow')#false)
  #
    facets =
      facets_for(facets)

  #
    search =
      search_for(prompt:, facets:)

    embedding =
      fast_embedding_for(search)

    k =
      rerank ? (8 * limit) : limit

    query =
      "SELECT id, distance FROM rag WHERE embedding MATCH ? AND k = ?"

    values =
      [embedding.pack('f*'), k]

  #
    indexed =
      %w[src subsrc author period published_at sentiment]

    indexed.each do |key|
      val = facets.delete(key)
      next unless val

      vals =
        [val].flatten.compact

      query <<
        " AND #{ key } IN (SELECT value FROM json_each(?))"

      values <<
        vals.to_json
    end

  # FIXME - ad-hoc assets...
    unless facets.empty?
      raise "illegal facets: #{ facets.keys.inspect }"
      chunk_ids =
        chunk_ids_for_facets(facets)

      query <<
        " AND chunk_id IN (SELECT value FROM json_each(?))"

      values <<
        chunk_ids.to_json
    end

  #
    query <<
      " ORDER by distance"

  #
    rows =
      @vec0.execute(query, values)

    return [] if rows.empty?

  #
    ids =
      rows.map{|row| row.first}

    chunks =
      @chunks.where(id: ids).to_a

    if rerank
      reranked =
        if rerank.to_s == 'slow'
          chunks = fast_rerank(prompt, chunks)
          chunks = chunks.first(4 * limit)
          slow_rerank(prompt, chunks)
        else
          fast_rerank(prompt, chunks)
        end

      chunks =
        reranked
    end

  #
    chunks.
      first(limit)
  end

  def fast_rerank(prompt, chunks)
    needle = fast_embedding_for(prompt)

    embeddings =
      Parallel.map(chunks, in_threads: 8) do |chunk|
        context = raw_context_for(chunk)
        fast_embedding_for(context)
      end

    index = Hash[ chunks.zip(embeddings) ]

    chunks.sort_by do |chunk|
      haystack = index[chunk]
      distance = euclidean_distance(needle, haystack)

      chunk[:_distance] = distance
    end
  end

  def euclidean_distance(a, b)
    raise unless (a.size == b.size)

    diff_squared = (0...a.size).reduce(0) do |sum, i|
      sum + (a[i] - b[i])**2
    end

    Math.sqrt(diff_squared)
  end

  def slow_rerank(prompt, chunks, max: 3000)
    _prompt = <<~____
      You are an expert data scientist, analyzing social media conversation
      for use as RAG context for the given AI prompt:

      <PROMPT>
        #{ prompt }
      </PROMPT>

      You should analyze the following list of social media conversations, and
      score each on a scale of 0.0 to 1.0, indicating how relevant each peice
      conversation is, with respect to its applicability to the above prompt.

      You are to return an array of JSON objects. Each object should contain
      the `id` and `score` for the conversation.  For example:

        {"id" : "$the_id", "score" : "$the_score"}

      Return valid JSON and nothing but valid JSON in your reply.
      Don't say anything else except the JSON.
    ____

    conversations = []

    chunks.each_with_index do |chunk, i|
      id = chunk.fetch(:key)
      conversation = chunk.fetch(:raw)
      conversations.push(id:, conversation:)
    end

    _prompt << "<POSTS>"
    _prompt << Utils.utf8ify(JSON.pretty_generate(conversations))
    _prompt << "</POSTS>"

    prompt_size = AI.count_tokens(_prompt)

    if prompt_size > max
      Say.say("TOO MANY TOKENS (#{ prompt_size } > #{ max }) - SPLITING!", color: :yellow)

      size = chunks.size
      half = size / 2
      a = chunks[0...half]
      b = chunks[half...size]

      unsorted = (slow_rerank(prompt, a) + slow_rerank(prompt, b))
      sorted = unsorted.sort_by{|chunk| chunk.fetch(:score)}.reverse
      return sorted
    else
      result = AI.completion_for(_prompt, temperature:0, format: 'json')
      unsorted = AI.json_parse_liberally(result)

      order = unsorted.sort_by{|h| h.fetch('score')}.reverse

      return(
        before =
          chunks

        after =
          order.map do |info|
            id = info.fetch('id')
            score = info.fetch('score')

            chunk = chunks.detect{|c| c.fetch(:key) == id} # FIXME they should all be there...

            if chunk
              chunk[:score] = score
              chunk[:segment] ||= chunk[:url][%r`r/[^/]+`] # FIXME
            else
              warn "chunk for key=#{ id } missing!"
            end

            chunk
          end.compact

        after
      )
    end
  end

  def rag_for(prompt, facets:{}, limit:16)
    chunks =
      chunks_for(prompt, facets:, limit:)

    return nil if chunks.empty?

    question = prompt
    refs = []

    prompt =
      [].tap do |l|
        if chunks.size > 0
          l.push '<CONTEXT>'

          chunks.each_with_index do |chunk, i|
            src = chunk.fetch(:src)
            url = chunk.fetch(:url)

            tldr = chunk.fetch(:tldr)

            raw = raw_context_for(chunk)

            l.push '  POST %s' % i
            l.push '  _____________'
            l.push '    URL:'
            l.push Utils.indent(url, n: 6)

            l.push ''
            l.push '    RAW:'
            l.push Utils.indent(raw, n: 6)

            refs.push(url)
          end

          l.push '</CONTEXT>'
        end

        l.push ''
        l.push '<INSTRUCTIONS>'

          if chunks.empty?
            l.push '  - Complete the following PROMPT.'
          else
            l.push '  - Complete the following PROMPT using the CONTEXT above *ONLY*.'
            l.push '  - Design a specific persona from the CONTEXT to answer as'
            l.push '  - The persona you design should be in synthesized from the CONTEXT and your answer.'
            l.push '  - Reply in the first person, as if you were that persona.'
            l.push '  - Inform your style and tone based on the persona.'
            l.push '  - As the persona, explain your reasoning, taking into account the context and specific aspects of that persona.'
            l.push '  - Do not reveal that you are an AI or indicate that you have constructed a persona.'
            l.push '  - Simply be that persona without explanation of how or why you choose it.'
          end
        l.push '</INSTRUCTIONS>'

        l.push ''
        l.push '<PROMPT>'
          l.push Utils.indent(question.capitalize, n: 2)
        l.push '</PROMPT>'

        l.map!{|line| clean(line)} # FIXME?
      end.join("\n").strip

      return({prompt:, refs:,})
  end

  def raw_context_for(chunk)
  # FIXME - support domains via dn/domain.com
    src = chunk.fetch(:src)
    key = chunk.fetch(:key)
    tldr = chunk.fetch(:tldr)
    id = key.split('/').last # r/subreddit/id
    link = find_link(id)

    title = link.get :Data, :Title
    body = link.get :Data, :Body

    post = [title, body].join("\n")
    comments = (link.get(:comments) || [])

    Utils.utf8ify(
      [].tap do |l|
        l.push '<POST>'
        l.push '  <TITLE>'
        l.push Utils.indent(title.upcase, n: 4)
        l.push '  </TITLE>'
        l.push '  <TLDR>'
        l.push Utils.indent(tldr, n: 4)
        l.push '  </TLDR>'
        l.push '  <BODY>'
        l.push Utils.indent(body, n: 4)
        l.push '  </BODY>'
        l.push '  <COMMENTS>'
        comments.each_with_index do |comment, index|
          l.push('    <COMMENT-%s>' % index)
          l.push Utils.indent(comment.get(:Data, :Body), n: 6)
          l.push('    </COMMENT-%s>' % index)
        end
        l.push '  </COMMENTS>'
        l.push '</POST>'
      end.join("\n")
    )
  end

  def clean(s)
    s.to_s.gsub(/[^[:print:]]/){|c| c == "\n" ? c : nil} # FIXME
  end

  def find_link(id)
    glob = "data/r/*/ro/links/#{ id }"

    Dir.glob(glob) do |match|
      path = Path.for(match).expand
      subreddit = path.parts.last(4).first
      ro = Ro::Root.new("data/r/#{ subreddit }/ro")
      link = ro.links.get(id) rescue nil
      return link if link
    end

    return nil
  end

  def fast_embedding_for(prompt, lang: :rs)
    cmd = "./bin/fastembed.#{ lang } /dev/stdin /dev/stdout"
    stdin = prompt
    stdout = IO.popen(cmd, 'w+'){|io| io.write(stdin); io.close_write; io.read}
    result = JSON.parse(stdout)

    case lang
      when :rs
        eval result.fetch('embedding') #FIXME
      when :js
        result
    end
  end

  extend Rag
end
