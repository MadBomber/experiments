# .../sqa/cli/commands/generate/configuration.rb

class Commands::Generate::Configuration < Commands::Base
  Commands.register "generate config", self

  desc "Generate configuration"

  option :apps, type: :array, default: [], desc: "Generate configuration for specific apps"

  def call(apps:, **options)
    puts "generated configuration for apps: #{apps.inspect}"
  end
end



__END__

commands_class = Foo::CLI::Commandss::Configure

commands_name = Foo::CLI::Commandss.commandss.detect { |name, cmd| cmd == commands_class }.first


puts commands_name  # Outputs: "generate config"

