# lib/database_connection.rb

require 'ai_client'  # A generic AI Client for many providers

require 'amazing_print'  # Pretty print Ruby objects with proper indentation and colors
require 'debug_me'       # A tool to print the labeled value of variables.
include DebugMe

require 'pg'             # Pg is the Ruby interface to the PostgreSQL RDBMS
require 'neighbor'       # Nearest neighbor search for Rails and Postgres
require 'active_record'
require 'active_model'
require 'active_support'
require 'yaml'           # STDLIB
require 'erb'            # STDLIB
require 'json'           # STDLIB
require 'pathname'       # STDLIB
require 'date'           # STDLIB
require 'open3'          # STDLIB
require 'json'           # STDLIB

require_relative 'models'

class DatabaseConnection
  class << self
    def setup
      config = load_configuration
      ActiveRecord::Base.establish_connection(config)
    end

    def load_configuration
      file = File.join(__dir__, '../db/database.yml')
      yaml_content = ERB.new(File.read(file)).result  # Process the YAML through ERB
      YAML.safe_load(yaml_content, aliases: true)[ENV['RACK_ENV'] || 'development']
    end
  end
end

DatabaseConnection.setup

DB = ActiveRecord::Base.connection
