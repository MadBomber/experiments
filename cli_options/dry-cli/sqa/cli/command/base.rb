# .../sqa/cli/command/base.rb

# Establish a Base command class that has global options
# available to all commands.

class SQA::CLI::Command::Base < Dry::CLI::Command
  option :debug,
    type:     :boolean,
    default:  false,
    desc:     'Print debug information',
    aliases:  %w[-d --debug]

  option :verbose,
    type:     :boolean,
    default:  false,
    desc:     'Print verbose information',
    aliases:  %w[-v --verbose]

  option :xyzzy,
    type:     :boolean,
    default:  false,
    desc:     "Magic",
    aliases:  %w[ -x --xyzzy ]
end
