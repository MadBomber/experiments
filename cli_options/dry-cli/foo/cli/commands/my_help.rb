# .../Foo/cli/commands/version.rb

# Override ?? the default dry-cli help command
class Commands::MyHelp < Dry::CLI::Command  # NOTE:  Not Commands::Base
  Commands.register "my_help", self, aliases: %w[ -m --my-help ]

  desc "Print My Usage"

  def call(*args)
    # Access the registry data
    registry_data = Commands.get([]) # gets the root of the regirsty

    debug_me('== REGISTRY =='){[
      :registry_data
    ]}

    puts "all these fail ..."

    # super

    # Foo::CLI::Commands.commands.each do |command_name, command|
    #   puts Dry::CLI::Banner.call(command, command_name)
    # end


    # if args.empty?
    #   puts Dry::CLI::Usage.call(Foo::CLI::Commands)
    # else
    #   command = Foo::CLI::Commands.get(args)
    #   if command.found?
    #     puts Dry::CLI::Banner.call(command.command, Dry::CLI::ProgramName.call(args))
    #   else
    #     puts "Commands '#{args.join(' ')}' not found"
    #   end
    # end
  end
end

