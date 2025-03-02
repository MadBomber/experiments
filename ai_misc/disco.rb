#! /usr/bin/env ruby
#  encoding: utf-8
# experiments/ai_misc/disco.rb
#
# See: https://gist.github.com/ahoward/abc555bf1a8e01dea8b83a10d791e8d5
#

script do
#
  help <<~____
    NAME
      disco

    TL;DR;
      a REPL that mines over a *million* social conversations with AI robotz

    REFS
      https://syntheticecho.com
  ____

#
  param :sentiment
  param :period

#
  run do
    setup!

    case
      when(argv.empty? || argv == %w[ - ])
        prompt = STDIN.read
      else
        prompt = argv.map{|file| IO.binread(file)}.join("\n\n")
    end

    handle(prompt)
  end

#
  run :console do
    dbsetup!
    binding.irb
  end

#
  def handle(prompt)
    about = <<~____
      - this is sample output from `disco`, short for *discovery*
      - `disco` brings millions of social voices to bear in any AI application
      - in addition to providing insights into disparate voices from a variety
        of audiences, it gives confirmation of correctness through citations
        of the actual conversations that inform its analyses
      - `disco` brings *the voice of humans* front and center, inside AI
      - we will resist our robot overlords by amplifying the voices of analog inteligence!
      - `disco`, is a [@drawohara](https://drawohara.io) joint, to follow along, and gain early access, goto -> https://drawohara.io/disco
        - developer preview API in the works
        - and a web application for those of you that don't program computers
    ____

    puts "# ABOUT"
    puts Utils.indent(about)
    puts

    puts "# PROMPT"
    puts Utils.wrap(prompt).gsub(/^/, '> ')
    puts

    n = 0
    max = 42

    @facets = {}

    if params.has_key?(:sentiment)
      @facets[:sentiment] = params.fetch(:sentiment).to_s.split(',')
    end

    if params.has_key?(:period)
      @facets[:period] = params.fetch(:period).to_s.split(',')
    end

    results = Hash.new

    audiences.each do |audience|
      results[audience] = Queue.new
    end

    consumer = Thread.new do
      audiences.each_with_index do |audience, index|
        result = results[audience].pop
        title = audience.fetch(:title)
        subreddits = audience.fetch(:subreddits)

        n += 1

        puts "## [AUDIENCE #{ n }](#audience-#{ n })"
        puts "#### #{ title }"
        subreddits.each do |subreddit|
          puts "- #{ subreddit }"
        end
        puts

        (result => completion:, references:, status:, error:)

        puts "### COMPLETION"
        if error
          puts Utils.wrap("ERROR: #{ error }").gsub(/^/, '> ')
        else
          puts Utils.wrap(completion).gsub(/^/, '> ')
        end
        puts

        puts "#### REFERENCES"
          references.each do |ref|
            puts "- #{ ref }"
          end
        puts

        break if n >= max # FIXME
      end
    end

    producer = Thread.new do
      #Parallel.map(audiences, in_threads: 8) do |audience|
      audiences.each do |audience|
        title = audience.fetch(:title)
        subreddits = audience.fetch(:subreddits)

        facets = @facets.merge(subreddit: subreddits)

        result = result_for(prompt, facets:)

        results[audience].push(result)

        sleep 1
      end
    end

    producer.join
    consumer.join
  end

  def result_for(prompt, facets:{})
    rag = rag_for(prompt, facets:, limit:16)

    if rag
      prompt = rag.fetch(:prompt)
      references = rag.fetch(:refs)
      completion = AI.completion_for(prompt)
      status = :success
      error = nil
    else
      prompt = prompt.to_s
      references = []
      completion = nil
      status = :failure
      error = '(insufficient content)'
    end

    Map.for(prompt:, completion:, references:, status:, error:)
  end

  def audiences(&block)
    config =
      YAML.load(IO.binread('./config/audiences.yml')).map{|_| Map.for(_)}

    accum =
      []

    config.each do |top|
      name = top.fetch(:name)
      audiences = top.fetch(:audiences)

      audiences.each do |sub|
        title = [name, sub.fetch(:name)].join(' // ')
        subreddits = sub.fetch(:subreddits)

        audience =
          Map.for(title:, subreddits:)

        if block
          block.call(audience)
        else
          accum.push(audience)
        end
      end
    end

    block ? nil : accum
  end

  def years
    yield 2024
    yield 2023
  end

  def periods_for_year(yyyy)
    [4,3,2,1].map{|q| "#{ yyyy }-q#{ q }"}
  end

  def dbsetup!(update: true)
    if update
      if(test ">", "./data/disco.sqlite", "./data/disco-console.sqlite")
        Say.say("./data/disco.sqlite => ./data/disco-console.sqlite", color: :yellow)
        FileUtils.cp("./data/disco.sqlite", "./data/disco-console.sqlite")
      end
    end

    db = "./data/disco-console.sqlite"

    @vec0 = SQLite3::Database.new(db)
    @vec0.enable_load_extension(true)
    SqliteVec.load(@vec0)
    @vec0.enable_load_extension(false)

    @db = Sequel.sqlite(db, setup_regexp_function: true)

    @chunks = @db[:chunks]
    @facets = @db[:facets]
  end
end

BEGIN {
  require_relative "../lib/pilot.rb"
}
