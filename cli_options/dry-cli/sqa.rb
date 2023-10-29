#!/usr/bin/env ruby
# .../sqa.rb

require 'debug_me'
include DebugMe

require 'dry/cli'

require 'require_all'

module SQA
end

require_rel './sqa/**/*.rb'


Dry::CLI.new(SQA::CLI::Command).call
