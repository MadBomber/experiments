# .../sqa/cli/command/generate/configuration.rb

module SQA::CLI::Command::Generate
class Configuration < Command::Base
  Command.register "generate config", self

  desc "Generate configuration"

  option :apps, type: :array, default: [], desc: "Generate configuration for specific apps"

  def call(apps:, **options)
    debug_me{[ :options ]}

    puts "generated configuration for apps: #{apps.inspect}"
  end
end
end


__END__

command_class = Foo::CLI::Commands::Configure

command_name = Foo::CLI::Commands.commands.detect { |name, cmd| cmd == command_class }.first


puts command_name  # Outputs: "generate config"

