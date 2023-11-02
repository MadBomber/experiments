# Foo/cli.rb

require 'dry/cli'

module Foo::CLI
end

# Load the Base and Version (aka PrintVersion) commands first
require_relative './cli/commands'


# execute the command line
Dry::CLI.new(Foo::CLI::Commands).call
