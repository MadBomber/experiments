#!/usr/bin/env ruby
# city_council.rb
#
# CityCouncil - Dynamic City Service Generation System
# This program acts as the governing body that can dynamically create and persist
# new city service departments as they are requested.

# Suppress Ruby 3.4.5 socket errors from DNS resolution threads
Thread.report_on_exception = false

require_relative 'smart_message/lib/smart_message'
require_relative 'vsm/lib/vsm'
require 'ruby_llm'
require 'json'
require 'fileutils'

require_relative 'common/health_monitor'
require_relative 'common/logger'

# Load all existing message types
Dir[File.join(__dir__, 'messages', '*.rb')].each { |file| require file }

# Load CityCouncil components
require_relative 'city_council/base'
require_relative 'city_council/intelligence'
require_relative 'city_council/governance'
require_relative 'city_council/operations'
require_relative 'city_council/cli_port'

module CityCouncil
  # CityCouncil module namespace
end

# Main execution
if __FILE__ == $0
  puts "🏛️ Starting CityCouncil..."

  Async do
    puts "🏛️ 🔄 CityCouncil starting in Async context..."
    
    council = CityCouncil::Base.new

    # Start with CLI if in interactive mode
    if ARGV.include?('--cli')
      puts "💬 Starting CLI interface..."
      port = CityCouncil::CLIPort.new(capsule: council.capsule)
      Thread.new { port.loop }
      council.logger.info("CLI interface started in separate thread")
    end

    puts "🏛️ 🚀 CityCouncil ready - VSM running in async context"
    council.start_governance
  end
end
