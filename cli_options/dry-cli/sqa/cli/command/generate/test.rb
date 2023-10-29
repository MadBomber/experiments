# .../sqa/cli/command/generate/test.rb

module SQA::CLI::Command::Generate
class Test < SQA::CLI::Command::Base
  SQA::CLI::Command::Generate.prefix.register "test", self

  desc "Generate tests"

  option :framework, default: "minitest", values: %w[minitest rspec]

  def call(framework:, **options)
    debug_me{[ :options ]}
    puts "generated tests - framework: #{framework}"
  end
end
end

