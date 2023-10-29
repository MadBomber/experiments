# .../sqa/cli/command/stop.rb

module SQA::CLI::Command
class Stop < Base
  SQA::CLI::Command.register "stop", self

  desc "Stop Foo machinery"

  option :graceful, type: :boolean, default: true, desc: "Graceful stop"

  def call(**options)
    debug_me{[ :options ]}

    puts "stopped - graceful: #{options.fetch(:graceful)}"
  end
end
end
