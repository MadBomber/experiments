#! /usr/bin/env ruby
#  encoding: utf-8
# Rile: subreddits.rb
# See: https://gist.github.com/ahoward/3be717f1f510eec4ffc17bcd4defc4ef#file-subreddits-L145-L172
#

script do
#
  help <<~____
    NAME
      subreddits

    SYNOPSIS
      subreddits data from a subreddit and vommit it to disk

    TL;DR;
      ~> ./bin/subreddits download r/science
      ~> ./bin/subreddits download .all --days 42
      ~> ./bin/subreddits r/subreddit

    REFS
      - ./config/rids.yml
      - https://api.boardreader.com/docs/#/Reddit/getRedditSearch
      - https://api.boardreader.com/docs/extended_query_syntax.php
  ____

#
  param :max, :value => :required
  param :days, :value => :required
  param :missing
  param :verbose

  param :backwards
  param :random
  param :force

  DAYS = 365 * 2
  MAX = 1000

#
  run :download do
    chroot!

    subreddit = argv.shift || help!

    days = Integer(params.fetch(:days){ DAYS })
    max = Integer(params.fetch(:max){ MAX })

    download!(subreddit:, days:, max:)
  end

#
  run :download, '.all' do
    chroot!

    days = Integer(params.fetch(:days){ DAYS })
    max = Integer(params.fetch(:max){ MAX })

    subreddits =
      subreddits_for(argv)

    backwards =
      params.has_key?(:backwards)

    random =
      params.has_key?(:random)

    force =
      params.has_key?(:force)

    if backwards
      subreddits.reverse!
    end

    if random
      subreddits.sort_by!{ rand }
    end

    if params.has_key?(:missing)
      missing = []

      subreddits.each do |subreddit|
        glob = "./data/#{ subreddit }/ro/links/*"
        count = Dir.glob(glob).size

        if count == 0
          missing << subreddit
        end
      end

      subreddits = missing
    end

    subreddits.each do |subreddit|
      FileUtils.mkdir_p("data/#{ subreddit }")
      FileUtils.mkdir_p("logs/#{ subreddit }")

      cmd = "subreddits download #{ subreddit } --days=#{ days } --max=#{ max } > logs/#{ subreddit }/download.txt 2>&1"

      Say.say(cmd, color: :magenta)

      begin
        utils.sys!(cmd) => status:
      rescue
        next
      end

      color = status == 0 ? :green : :red

      Say.say("#{ cmd } #=> #{ status }", color: color)

      Say.say(`ag SUCCESS -A1 logs/#{ subreddit }/download.txt`, color: :yellow)
    end
  end

  run :download, '.monitor' do
    system "tail -F logs/r/*/download.txt"
  end

#
  run :download, '.counts' do
    chroot!

    subreddits =
      Dir.glob('./data/r/*').map{|it| 'r/' + File.basename(it) }

    total = 0
    subreddits.each do |subreddit|
      glob = "./data/#{ subreddit }/ro/links/*"
      count = Dir.glob(glob).size
      total += count
      puts "#{ subreddit }: #{ count }"
    end
    puts "------"
    puts "total: #{ total }"
  end

#
  def download!(subreddit:, days:DAYS, max:MAX) # FIXME 730 * 1000 => 730_000
    end_date = Date.today - 3 # try to avoid trecent and _unscored_ links in the sg feed
    start_date = end_date - days
    date_range = start_date .. end_date

    n = 0

    per_day =  [(MAX / DAYS.to_f).ceil, 1].max * 10

    ThreadPool.new do |tp|
      tp.run do
        date_range.reverse_each do |date|
          tp.process!(date:)
        end
      end

      tp.process do |date:|
        n = 0

        download_links!(subreddit:, date:, max:per_day) do |link|
          break if n > max
          comments = link.comments
          next if comments.empty?

          path = "./data/#{ subreddit }/ro/links/#{ link.ExtKey }/attributes.json"
          json = JSON.pretty_generate(link)

          utils.binwrite(path, json)

          n += 1
        end

        tp.success! subreddit:, date:, n:
      end
    end
    #RequestsUsed":8494,"RequestsLimit":"400000","ConcurrentRequests":"2","RequestsInQueue":"0","ActiveConcurrentRequestsAllowed":"10","MaxConcurrentRequests":"20","DailyVolume":2208,"Request":
  end

  def download_links!(subreddit:, date:, max: 10, &block)
    forum_ext_key = forum_ext_key_for(subreddit)

    filter_date_from = unix_time_for(date)
    filter_date_to = unix_time_for(date + 1)

    scores = [ # FIXME?
      1024,
      512,
      256,
      128,
      42,
      11
    ]

    n =
      0

    accum = []

    scores.each do |score|
      params = {
        query:               "@forum_ext_key #{ forum_ext_key }",
        filter_thing:         "link",
        filter_date_from:     filter_date_from,
        filter_date_to:       filter_date_to,
        filter_num_comments: "gte#{ 2 }",
        filter_upvote_ratio: "gte#{ 0.80 }",

        max_matches:         100_000,
        sort_mode:           "time_desc",
        rt:                   "json",
        body:                 "full_text",
        mode:                 "full",
        highlight:           0,
      }

      if score > 0
        params[:filter_score] = "gte#{ score }"
      end

      offset = 0
      limit = 1000

      catch(:no_more_data) do
        loop do
          params[:offset] = offset
          params[:limit] = limit

          at = Time.now.utc
          url = SocialGist.api.reddit_search_url_for(:params => params)

          result = download(url)

          error = result.error
          data = result.data

          if error
            if [18].include?(error.code)
              throw :no_more_data
            else
              abort error.inspect
            end
          else
            matches = data.get(:response, :Matches, :Match) || []
            size = matches.size

            if size == 0
              throw :no_more_data
              raise if offset == 0 # FIXME
            else
              matches.each do |match|
                link = Map.for(match)
                comments = download_comments!(subreddit:, link:)
                link[:comments] = comments

                block ? block.call(link) : accum.push(link)

                n += 1

                if n >= max
                  throw :no_more_data
                end
              end
            end

            offset += limit
          end
        end
      end

      if n > 0
        return(block ? nil : accum)
      end
    end

    block ? nil : []
  end

  def download_comments!(subreddit:, link:, &block)
    forum_ext_key = forum_ext_key_for(subreddit)
    link_id = link.get(:ExtKey)

    filter_date_from = 0
    filter_date_to = unix_time_for(Date.today + 1)

    scores = [
      42,
      11,
      0
    ]
    n = 0

    scores.each do |score|
      params = {
        query:               "@forum_ext_key #{ forum_ext_key } @parent_id #{ link_id }",
        filter_thing:         "comment",
        filter_date_from:     filter_date_from,
        filter_date_to:       filter_date_to,

        max_matches:         100_000,
        sort_mode:           "time_desc",
        rt:                   "json",
        body:                 "full_text",
        mode:                 "full",
        highlight:           0,
      }

      if score > 0
        params[:filter_score] = "gte#{ score }"
      end

      offset = 0
      limit = 1000

      accum = []

      catch(:no_more_data) do
        loop do
          params[:offset] = offset
          params[:limit] = limit

          at = Time.now.utc
          url = SocialGist.api.reddit_search_url_for(:params => params)

          result = download(url)

          error = result.error
          data = result.data

          if error
            if [18].include?(error.code)
              throw :no_more_data
            else
              raise error.to_json
              #STDIN.tty? ? binding.pry : abort # FIXME
            end
          else
            matches = data.get(:response, :Matches, :Match) || [] # FIXME
            size = matches.size

            if size == 0
              throw :no_more_data
              raise if offset == 0 # FIXME
            else
              matches.each do |match|
                comment = match
                block ? block.call(comment) : accum.push(comment)
                n += 1
              end
            end

            offset += limit
          end
        end
      end

      if n > 0
        return(block ? nil : best(accum))
      end
    end

    block ? nil : []
  end

  def best(comments)
    scores = comments.map{|comment| comment.get :Data, :Score}
    percentile = percentile(scores, 90)

    best = []
    highest = nil

    comments.each do |comment|
      comment_author = comment.get :Data, :Author
      comment_author_karma = comment.get :Data, :AuthorKarma
      comment_author_url = comment.get :Data, :AuthorUrl
      next if comment_author =~ /Moderator/

      score = comment.get :Data, :Score
      next if score < percentile

      reply = comment.get :Data, :Body
      next if reply.strip == ''

      best << comment
      highest ||= comment

      if comment.get(:Data, :Score) > highest.get(:Data, :Score)
        highest = comment
      end
    end

    if best.size == 0
      best = [highest].compact
    end

    best
  end

  def percentile array, p
    sorted_array = array.sort
    rank = (p.to_f / 100) * (array.length + 1)

    return nil if array.length == 0

    if rank.truncate > 0 && rank.truncate < array.length
      sample_0 = sorted_array[rank.truncate - 1]
      sample_1 = sorted_array[rank.truncate]

      fractional_part = (rank - rank.truncate).abs
      (fractional_part * (sample_1 - sample_0)) + sample_0
    elsif rank.truncate == 0
      sorted_array.first.to_f
    elsif rank.truncate == array.length
      sorted_array.last.to_f
    end
  end

  RATE_LIMTER = RateLimiter.new

  def download(url)
    time = Time.now.utc.iso8601(2)
    msg = JSON.pretty_generate(url:, time:)
    Say.say(msg, color: :cyan) #if params[:verbose]

    json = nil
    data = nil
    error = nil

    try_hard! do
      json = RATE_LIMTER.limit{ curl(url) }
      data = Map.for(JSON.parse(json))
      error = data.get(:response, :Error)

      if error
        code = data.get(:response, :Error, :ErrorCode).to_i
        raise if [48, 18].include?(code) # rate limiting...
        error.set(:code, code)
      end
    end

    result = Map.for(json:, data:, error:)
  end

  def try_hard!(n: 11, &block)
    errors = []

    n.to_i.times do |i|
      begin
        return block.call
      rescue => error
        errors.push(error)
        sleep(2 ** i)
      end
    end

    raise errors.last
  end

  def unix_time_for(date)
    date.to_time.to_i
  end

  def forum_ext_key_for(subreddit)
    config.get(:social_gist, :subreddits, subreddit) or raise("no social_gist config for #{ subreddit }")
    #rids.fetch(subreddit.to_s){ raise "key not found for subreddit=#{ subreddit.inspect }" }
  end

  def rids
    @rids ||= YAML.load(IO.binread('./config/rids.yaml'))
  end
end

BEGIN {
  require_relative "../lib/pilot.rb"
}
