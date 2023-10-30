# sqa/cli.rb

require 'dry/cli'

require 'require_all'

module SQA::CLI
end

# Load the Base and Version (aka PrintVersion) commands first
require_relative 'cli/command'

require_rel './cli/**/*.rb'

# execute the command line
Dry::CLI.new(SQA::CLI::Command).call
