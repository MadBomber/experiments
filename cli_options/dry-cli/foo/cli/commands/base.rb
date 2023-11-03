# .../Foo/cli/commands/base.rb

# Establish a Base command class that has global options
# available to all commands.

class Foo::CLI::Commands::Base < Dry::CLI::Command
  global_header "== Base Global Header =="
  global_footer "== Base Global Footer =="

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
