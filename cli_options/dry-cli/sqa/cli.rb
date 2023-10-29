# sqa/cli.rb

require 'dry/cli'

require 'require_all'

module SQA::CLI
end

require_rel './cli/**/*.rb'

Dry::CLI.new(SQA::CLI::Command).call
