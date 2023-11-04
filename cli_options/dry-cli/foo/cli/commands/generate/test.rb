# .../sqa/cli/commands/generate/test.rb

require 'stringio'

class Commands::Generate::Test < Commands::Generate # Base
  VERSION = "2.0.0-test"

  Commands.register "generate test", self
  Commands.register "generate test version", PrintVersion.new(VERSION), aliases: %w[--version]

  header "++ TEST header only no footer ++"

  desc "Generate tests"

  option :framework, default: "minitest", values: %w[minitest rspec]

  def call(framework:, **options)
    puts "generated tests - framework: #{framework}"
  end

  # Capture the Dry::CLI standard help text irnoring
  # the exit(0) and return that help text as a String

  def self.help
    help_text = StringIO.new
    $stdout   = help_text
    cli       = Dry::CLI.new(self)

    begin
      cli.call(arguments: ['--help'])
    rescue SystemExit
      # ignore
    end

    $stdout = STDOUT

    help_text.string
  end
end

