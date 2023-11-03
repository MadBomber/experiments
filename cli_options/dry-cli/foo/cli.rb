# foo/cli.rb

require 'dry/cli'
require_relative 'monkey_patch_dry_cli'

module Foo::CLI
end

# Load the Base and Version (aka PrintVersion) commands first
# followed by all other commands and sub-commands
require_relative './cli/commands'


# #xecute the command line
Dry::CLI.new(Foo::CLI::Commands).call
