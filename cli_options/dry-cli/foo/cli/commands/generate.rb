# .../Foo/cli/commands/generate.rb

class Foo::CLI::Commands::Generate < Commands::Base # Dry::CLI::Command
  VERSION = "1.0.0-generate"

  option :gen_z,
    aliases:  %w[ -z -Z ],
    type:     :boolean, # makes this a flag
    default:  false,
    desc:     "Allow Gen Z to use these commands"

  Commands.register "generate", self, aliases: ["g"]
  Commands.register "generate version", PrintVersion.new(VERSION), aliases: %w[--version]


  # As a Command class, Generate will respond to a call when no subcommand
  # is given on the command line.  This makes the sub commands optional.
  # If Generate were a module and/or registered as anonymous then the
  # sub-commands are required.

  def call(**args)
    # Do something useful that does not invoke the
    # optional sub-commands.

    puts "Displaying the detailed help message for all subcommands"
    puts "Subcommands: #{subcommands.keys.join(', ')}"
    puts

    subcommands.keys.each do |sub_kommand_name|
      puts "\nSubcommand: #{sub_kommand_name} ..."
      kommand = subcommands[sub_kommand_name].command
      if kommand.respond_to?(:help)
        puts kommand.help
      else
        puts " == Sorry: Detailed help is not available."
      end
    end
  end
end


Dir.glob("#{__dir__}/generate/*.rb")
  .each do |file|
  # print "Loading #{file} ... "
  require_relative file
  # puts "done."
end

