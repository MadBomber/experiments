# .../sqa/cli/command/generate/configuration.rb

module SQA::CLI::Command::Generate
class Configuration < SQA::CLI::Command::Base
  SQA::CLI::Command::Generate.prefix.register "config", self

  desc "Generate configuration"

  option :apps, type: :array, default: [], desc: "Generate configuration for specific apps"

  def call(apps:, **options)
    debug_me{[ :options ]}

    puts "generated configuration for apps: #{apps.inspect}"
  end
end
end
