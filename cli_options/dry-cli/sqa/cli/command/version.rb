# .../sqa/cli/command/version.rb


module SQA::CLI::Command
class Version < Base
  Command.register "version", self, aliases: %w[--version]

  desc "Print version"

  def initialize(version=SQA::VERSION)
    @version = version
  end

  def call(**options)
    puts @version
    exit(0)
  end
end
end

# Create a short-cut to the class
PrintVersion = SQA::CLI::Command::Version
