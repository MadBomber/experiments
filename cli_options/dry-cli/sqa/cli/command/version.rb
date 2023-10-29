# .../sqa/cli/command/version.rb

module SQA::CLI::Command
class Version < Base
  SQA::CLI::Command.register "version", self, aliases: ["v", "-v", "--version"]

  desc "Print version"

  def call(**options)
    debug_me{[ :options ]}
    puts "1.0.0"
  end
end
end
