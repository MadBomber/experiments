# .../sqa/cli/commands/generate/test.rb

class Commands::Generate::Test < Commands::Base
  VERSION = "2.0.0-test"

  Commands.register "generate test", self
  Commands.register "generate test version", PrintVersion.new(VERSION), aliases: %w[--version]

  desc "Generate tests"

  option :framework, default: "minitest", values: %w[minitest rspec]

  def call(framework:, **options)
    puts "generated tests - framework: #{framework}"
  end
end

