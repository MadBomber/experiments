#! /usr/bin/env ruby
# encoding: utf-8
# See: https://github.com/ahoward/ima/blob/main/lib/ima/task.rb
#
module Ima
  class Task
    def Task.dir
      Ima.dir('tasks')
    end

    def Task.exist?(name)
      Dir.glob(File.join(Task.dir, "#{ name }*")).size > 0
    end

    def Task.name_for(arg, *args)
      '/' + [arg, *args].join('/').scan(%r`[^/]+`).join('/')
    end

    def Task.parse(argv, task: nil)
      shift = false

      if task.nil?
        if argv.first.to_s.start_with?('/')
          task = argv[0]
          shift = true
        end
      end

      if task.nil? && Task.exist?('/default')
        task = '/default'
      end

      if task.nil?
        task = Task.builtin
      else
        task = Task.build(task)
      end

      return nil if task.nil?

      argv.shift if shift

      if argv.size > 0
        cmd = argv[0..-1].join(' ').strip
        task.instructions = task.instructions + "\n- #{ cmd }"
      end

      return task
    end

    def Task.build(task)
      names = Task.names_for(task)

      tasks = names.map{|name| Task.load(name)}.compact

      return nil if tasks.empty?

      task = tasks.shift

      while tasks.size > 0
        task = task + tasks.shift
      end

      task
    end

    def Task.names_for(name)
      parts = name.split('/')
      parts = parts.reject { |c| c.empty? }

      (1..parts.size).map do |i|
        '/' + parts.take(i).join('/')
      end
    end

    def Task.load(task)
      return nil unless Task.exist?(task)

      name = Task.name_for(task)
      data = Task.data_for(name)
      task = Task.new(name, data)
    end

    def Task.load!(task)
      task = Task.load(task)
      raise Abort.new('no such task %s' % task) unless task
      task
    end

    def Task.data_for(name)
      data = Map.new

      prefix = File.join(Task.dir, name)

      Dir.glob("#{ prefix }.{yml,yaml,json}") do |file|
        ext = file.split('.', 2).last
        buf = IO.binread(file)

        hash =
          case
            when ext =~ /yml|yaml/
              YAML.safe_load(buf)
            when ext =~ /json/
              JSON.parse(buf)
            else
              raise file
          end

        data.apply(hash)
      end

      if test(?e, "#{ prefix }.md")
        md = FrontMatterParser::Parser.parse_file("#{ prefix }.md")
        data.apply(md.front_matter)
        data[:instructions] = md.content
      end

      if test(?e, "#{ prefix }/instructions.md")
        data[:instructions] = IO.binread("#{ prefix }/instructions.md")
      end

      if test(?e, "#{ prefix }/system.md")
        data[:system] = IO.binread("#{ prefix }/system.md")
      end

      data
    end

    def Task.builtin
      data =
        {
          system: <<~____,
            - you are a universal unix filter, and always produce simple,
              plaintext, line based output.
            - you are adept at understanding both CODE and PROSE input.
            - your job is to filter input lines, relaying those that do not
              require modification to the output, and altering or enhancing
              those that do, based on your INSTRUCTIONS
            - when you do not undertand a task, you make your best guess
              rather than asking for clarification.
            - you are strictly business, quiet, and neither explain yourself
              nor add commentary unless explicity asked.
          ____

          instructions: <<~____,
          ____
        }

      new('/builtin', data)
    end

    def Task.squeeze(a, b)
      a = a.to_s.scan %r`[^/]+`
      b = b.to_s.scan %r`[^/]+`

      parts = []

      loop do
        break if a.empty? && b.empty?
        pair = [a.shift, b.shift]

        case
          when pair.first == pair.last
            parts << pair.first
          else
            parts << pair.compact.join('/')
        end
      end

      '/' + parts.join('/')
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

      srcs = [srcs].compact.flatten.join(' ').scan(%r`[^\s]+`)

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
        load_context(['./lib', './src', './app', './config', './bin'])
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

    def +(other)
      name = Task.squeeze(self.name, other.name)

      system = [self.system.to_s.strip, other.system.to_s.strip].join("\n")
      instructions = [self.instructions.to_s.strip, other.instructions.to_s.strip].join("\n")

      data = self.data.dup.apply(other.data)
      data[:system] = system
      data[:instructions] = instructions

      Task.new(name, data)
    end

    def inherit!(other)
      self
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
  end
end
