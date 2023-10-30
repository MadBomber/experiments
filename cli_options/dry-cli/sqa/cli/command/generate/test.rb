# .../sqa/cli/command/generate/test.rb

module SQA::CLI::Command::Generate
class Test < Command::Base
  VERSION = "2.0.0-test"

  Command.register "generate test", self
  Command.register "generate test version", PrintVersion.new(VERSION), aliases: %w[--version]

  desc "Generate tests"

  option :framework, default: "minitest", values: %w[minitest rspec]

  def call(framework:, **options)
    debug_me{[ :options ]}
    puts "generated tests - framework: #{framework}"
  end
end
end

