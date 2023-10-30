# sqa/cli/command.rb

# Establish the command registry
module SQA::CLI::Command
  extend Dry::CLI::Registry
end

# Create a short-cut to the registry
Command = SQA::CLI::Command

require_relative 'command/base'
require_relative 'command/version'
