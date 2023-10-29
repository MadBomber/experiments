#!/usr/bin/env ruby
# sqa.rb

require 'debug_me'
include DebugMe

require 'dry/cli'

module SQA
  module CLI
    module Command
      extend Dry::CLI::Registry

      class Base < Dry::CLI::Command
        option :debug,
          type:     :boolean,
          default:  false,
          desc:     'Print debug information'

        option :verbose,
          type:     :boolean,
          default:  false,
          desc:     'Print verbose information'

        class << self
          @@command_classes = []

          def inherited(subclass)
            @@command_classes << subclass
            super
          end


          def command_classes
            @@command_classes
          end


          def command(name=nil)
            return self.class_variable_get(:@@command) if name.nil?
            self.class_variable_set(:@@command, name)
          end
        end
      end
    end
  end
end


module SQA
  module CLI
    module Command
      class Version < Base
        SQA::CLI::Command.register "version", self, aliases: ["v", "-v", "--version"]

        desc "Print version"

        def call(**options)
          debug_me{[ :options ]}
          puts "1.0.0"
        end
      end


      class Echo < Base
        SQA::CLI::Command.register "echo", self

        desc "Print input"

        argument :input, desc: "Input to print"

        example [
          "             # Prints 'wuh?'",
          "hello, folks # Prints 'hello, folks'"
        ]

        def call(input: nil, **options)
          debug_me{[ :options ]}
          if input.nil?
            puts "wuh?"
          else
            puts input
          end
        end
      end


      class Start < Base
        SQA::CLI::Command.register "start", self

        desc "Start Foo machinery"

        argument :root, required: true, desc: "Root directory"

        example [
          "path/to/root # Start Foo at root directory"
        ]

        def call(root:, **options)
          debug_me{[ :options ]}
          puts "started - root: #{root}"
        end
      end


      class Stop < Base
        SQA::CLI::Command.register "stop", self

        desc "Stop Foo machinery"

        option :graceful, type: :boolean, default: true, desc: "Graceful stop"

        def call(**options)
          debug_me{[ :options ]}

          puts "stopped - graceful: #{options.fetch(:graceful)}"
        end
      end


      class Exec < Base
        SQA::CLI::Command.register "exec", self

        desc "Execute a task"

        argument :task, type: :string, required: true,  desc: "Task to be executed"
        argument :dirs, type: :array,  required: false, desc: "Optional directories"

        def call(task:, dirs: [], **options)
          debug_me{[ :options ]}
          puts "exec - task: #{task}, dirs: #{dirs.inspect}"
        end
      end


      module Generate
        def self.prefix
          main_command = nil

          SQA::CLI::Command.register "generate", aliases: ["g"] do |an_object|
            main_command = an_object
          end

          main_command
        end
      end


      module Generate
        class Configuration < Base
          Generate.prefix.register "config", Generate::Configuration

          desc "Generate configuration"

          option :apps, type: :array, default: [], desc: "Generate configuration for specific apps"

          def call(apps:, **options)
            debug_me{[ :options ]}

            puts "generated configuration for apps: #{apps.inspect}"
          end
        end

        class Test < Base
          Generate.prefix.register "test",   Generate::Test

          desc "Generate tests"

          option :framework, default: "minitest", values: %w[minitest rspec]

          def call(framework:, **options)
            debug_me{[ :options ]}
            puts "generated tests - framework: #{framework}"
          end
        end
      end
    end
  end
end

Dry::CLI.new(SQA::CLI::Command).call
