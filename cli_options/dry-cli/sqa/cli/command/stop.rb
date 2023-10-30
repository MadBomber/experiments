# .../sqa/cli/command/stop.rb

module SQA::CLI::Command
class Stop < Base
  VERSION = '0.1.0-stop'

  Command.register "stop", self
  Command.register "stop version", PrintVersion.new(VERSION), aliases: %w[--version]

  desc "Stop Foo machinery"

  option :graceful, type: :boolean, default: true, desc: "Graceful stop"

  def call(**options)
    debug_me{[ :options ]}

    puts "stopped - graceful: #{options.fetch(:graceful)}"
  end
end
end
