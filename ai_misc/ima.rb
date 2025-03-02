#! /usr/bin/env ruby
# encoding: utf-8
# See: https://gist.github.com/ahoward/f110e1f24fe122a6bf691c1c000cb7b3

script do
#
  tldr <<~____
    `ima` is an AI enabled universal unix filter
  ____

#
  param :input, value: :required
  param :task, value: :required
  param :context, value: :required

  option :prompt, :p
  option :blind, :b

#
  run do
    load_task!
    load_input!
    load_context!
    run_task!
  end

#
  def load_task!
    task = params[:task]

    @task =
      Task.parse(argv, task:)
  end

#
  def load_input!
    input = params[:input]
    blind = params.has_key?(:blind)

    @input =
      if blind
        nil
      else
        if input
          IO.binread(input)
        else
          STDIN.read
        end
      end

    @task.input = @input
  end

#
  def load_context!
    @context =
      if params[:context]
        Task.load_context(params[:context])
      else
        Task.load_default_context
      end

    @task.context = @context
  end

#
  def run_task!
    if params.has_key?(:prompt)
      puts @task.prompt
      exit 42
    end

    completion =
      completion_for(@task)

    STDOUT.puts(
      completion
    )
  end

#
  class Task
    def Task.config_dir
      File.join(Dir.home, '.ima')
    end

    def Task.exist?(name)
      Dir.glob(File.join(Task.config_dir, "#{ name }*")).size > 0
    end

    def Task.name_for(arg, *args)
      '/' + [arg, *args].join('/').scan(%r`[^/]+`).join('/')
    end

    def Task.parse(argv, task: nil)
      if task.nil?
        if argv.first.to_s.start_with?('/')
          task = argv.shift
        end
      end

      if task.nil? && Task.exist?('/default')
        task = '/default'
      end

      task =
        if task.nil?
          Task.default
        else
          Task.load(task)
        end

      if argv.size > 0
        cmd = argv.join(' ').strip
        task.instructions = task.instructions + "\n- #{ cmd }"
      end

      return task
    end

    def Task.load(task)
      name = Task.name_for(task)
      data = Task.data_for(name)
      task = Task.new(name, data)
    end

    def Task.data_for(name)
      data = Map.new
      prefix = File.join(Task.config_dir, name)
      data[:instructions] = IO.binread(File.join(prefix, 'instructions.md')) rescue ''
      data[:system] = IO.binread(File.join(prefix, 'system.md')) rescue ''
      data
    end

    def Task.default
      data =
        {
          system: <<~____,
            - you are a universal unix filter, and always produce simple,
              plaintext, line based output.
            - you are adept at understanding both CODE and PROSE input.
            - your job is to filter input lines, relaying those that do not
              require modification to the output, and altering or enhancing
              those that do
            - when you do not undertand a task, you make your best guess
              rather than asking for clarification.
            - you are strictly business, quiet, and neither explain yourself
              nor add commentary unless explicity asked.
          ____

          instructions: <<~____,
          ____
        }

      new('/default', data)
    end

    attr_accessor :name
    attr_accessor :data
    attr_accessor :system
    attr_accessor :instructions
    attr_accessor :input
    attr_accessor :context

    def initialize(name, data = {})
      @name = Task.name_for(name)
      @data = Map.for(data)
      @system = @data[:system].to_s.strip
      @instructions = @data[:instructions].to_s.strip
      @input = nil
      @context = nil
    end

    def prompt
      prompt = []

      if Task.present?(@system)
        prompt << <<~____

          Given the following SYSTEM:

          <SYSTEM>\n#{@system}\n</SYSTEM>
        ____
      end

      if Task.present?(@context)
        prompt << <<~____

          Consider the following CONTEXT:

          <CONTEXT>\n#{JSON.pretty_generate(@context)}\n</CONTEXT>
        ____
      end

      if Task.present?(@instructions)
        if Task.present?(@input)
          prompt << <<~____

            Your INSTRUCTIONS are as follows:

            <INSTRUCTIONS>
              Carefully consider the INPUT below, then:

              #{@instructions}
            </INSTRUCTIONS>

            <INPUT>\n#{@input}\n</INPUT>
          ____
        else
          prompt << <<~____

            Your INSTRUCTIONS are as follows:

            <INSTRUCTIONS>\n#{@instructions}\n</INSTRUCTIONS>
          ____
        end
      else
        if Task.present?(@input)
          prompt << <<~____

            Your INSTRUCTIONS are as follows:

            <INSTRUCTIONS>
              Carefully consider the INPUT below.
              Then make your best judgement regarding how to respond.
            </INSTRUCTIONS>

            <INPUT>\n#{@input}\n</INPUT>
          ____
        else
          prompt << <<~____

            Your INSTRUCTIONS are as follows:

            <INSTRUCTIONS>
              Tell me a random quote or poem.
              End with a newline and then "-- $author"
            </INSTRUCTIONS>
          ____
        end
      end

      Task.utf8ify(prompt.join("\n\n"))
    end

    def Task.present?(value)
      value.to_s.strip.size > 0
    end

    def Task.utf8ify(*args)
      string = args.join
      string.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
    end

    def Task.load_context(srcs, max: 10_000) # FIXME
      context = []
      total = 0
      mutex = Mutex.new

      srcs = [srcs].compact.flatten

      Parallel.each(srcs, in_threads: 8) do |src|
        glob = test(?d, src) ? "#{ src }/**/**" : src

        Dir.glob(glob) do |entry|
          next unless test(?f, entry)

          filename = entry
          contents = read_iff_plaintext(filename)
          next unless contents

          tokens = AI.count_tokens(contents)

          mutex.synchronize do
            total += tokens
            raise Parallel::Break if total >= max
            context << {filename: , contents:}
          end
        end
      end

      context
    end

    def Task.load_default_context
      repo = %w[ .git ].any?{|it| test(?e, it)}

      if repo
        load_context './lib', './src', './app', './config', './bin'
      else
        []
      end
    end

    def Task.read_iff_plaintext(file)
      begin
        File.open(file, 'rb') do |fd|
          buf = fd.read(8192)
          return nil if buf.nil?
          return nil if buf.bytes.any? { |byte| byte == 0 }
          return nil unless buf.force_encoding(Encoding::UTF_8).valid_encoding?
          buf << fd.read
        end
      rescue
        nil
      end
    end
  end

# FIXME - move into an AI abstraction/module?
  def completion_for(task)
    system = task.system
    prompt = task.prompt
    completion = ai_that_shit!(prompt)
    completion.gsub!(/^```.*$/, '')  # strip code block start tags
    completion.gsub!(/```\s*$/, '')  # strip code block end tags
    completion.strip
  end

# FIXME - move into an AI abstraction/module?
  def ai_that_shit!(...)
    ai = AI::Groq
    #ai = AI::Mistral
    completion = ai.completion_for(...)
  end
end

BEGIN {
  bindir = File.expand_path(__dir__)
  root = File.dirname(bindir)
  libdir = File.join(root, 'lib')

  require 'thread'
  require 'json'

  ENV['BUNDLE_GEMFILE'] = String.new

  require 'parallel'
  require 'map'

  require "#{ libdir }/script.rb"
  require "#{ libdir }/ai.rb"
}
