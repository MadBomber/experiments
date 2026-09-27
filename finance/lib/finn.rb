require "ruby_llm"
require "dotenv/load"
require "httparty"
require "json"
require "uri"
require "date"

require_relative "finn/prompts"
require_relative "finn/tools/yahoo_finance"

Dir[File.join(__dir__, "finn", "tools", "*.rb")].sort.each { |f| require f }

require_relative "finn/agent"
