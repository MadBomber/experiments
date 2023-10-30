# .../sqa/cli/command/generate.rb

module SQA::CLI::Command::Generate
  VERSION = "1.0.0-generate"

  Command.register "generate", aliases: ["g"]
  Command.register "generate version", PrintVersion.new(VERSION), aliases: %w[--version]
end
