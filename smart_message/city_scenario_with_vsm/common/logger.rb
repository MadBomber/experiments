#!/usr/bin/env ruby
# examples/multi_program_demo/common/logger.rb

module Common
  module Logger
    def setup_logger(options = {})
      # Auto-detect program name from filename if not provided
      program_name = options.delete(:name) || File.basename($0, '.rb')

      # Build options with defaults
      opts = {
        log_file: "log/#{program_name}.log",
        level: ::Logger::INFO
      }.merge(options)

      # Configure SmartMessage with the logger
      SmartMessage.configure do |config|
        config.logger = SmartMessage::Logger::Default.new(**opts)
      end

      # Store and return the logger instance
      @logger = SmartMessage::Logger.default
    end

    def logger
      # Return existing logger or create with defaults
      @logger ||= setup_logger
    end
  end
end
