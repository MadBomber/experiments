# frozen_string_literal: true

require "lumberjack"

LOG_FILE = File.join(__dir__, "..", "log", "terrarium.log")
Dir.mkdir(File.dirname(LOG_FILE)) unless Dir.exist?(File.dirname(LOG_FILE))

File.truncate(LOG_FILE, 0) if File.exist?(LOG_FILE)
LOGGER = Lumberjack::Logger.new(LOG_FILE, level: :debug)
