# sqa/lib/sqa/commands.rb

# Adds command options to SQA.config
require_relative "plugin_manager"

module SQA::Commands
	# Establish the command registry
  extend Dry::CLI::Registry
end

Commands = SQA::Commands


load_these_first = [
  "#{__dir__}/commands/base.rb",
].each { |file| require_relative file }

Dir.glob("#{__dir__}/commands/*.rb")
  .reject{|file| load_these_first.include? file}
  .each do |file|
  require_relative file
end
