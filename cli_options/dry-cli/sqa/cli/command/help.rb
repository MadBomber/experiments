# .../sqa/cli/command/version.rb

# Override the default dry-cli help command
module SQA::CLI::Command
class Help < Dry::CLI::Command
  Command.register "help", self, aliases: %w[ -h --help ]

  desc "Print Usage"

  def call(*args)
    debug_me('== My Help Args =='){[
      :args
    ]}

    # TODO: add a header and a footer class method like the
    #       existing desc method so that are the global level
    #       and the command level we can wrap the help text
    #       with stuff.

    puts "== header =="

    # Access the registry data
    registry_data = Command.get([]) # gets the root of the regirsty

    debug_me('== REGISTRY =='){[
      :registry_data
    ]}

    puts "all these fail ..."

    # super

    # SQA::CLI::Command.commands.each do |command_name, command|
    #   puts Dry::CLI::Banner.call(command, command_name)
    # end


    # if args.empty?
    #   puts Dry::CLI::Usage.call(SQA::CLI::Command)
    # else
    #   command = SQA::CLI::Command.get(args)
    #   if command.found?
    #     puts Dry::CLI::Banner.call(command.command, Dry::CLI::ProgramName.call(args))
    #   else
    #     puts "Command '#{args.join(' ')}' not found"
    #   end
    # end

    puts "== footer =="
  end
end; end

