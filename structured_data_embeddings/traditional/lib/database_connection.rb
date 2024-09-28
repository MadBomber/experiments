# lib/database_connection.rb

require 'amazing_print'
require 'debug_me'
include DebugMe

require 'pg'
require 'neighbor'
require 'active_record'
require 'active_model'
require 'active_support'
require 'yaml'
require 'erb'
require 'json'
require 'pathname'
require 'date'
require 'open3'
require 'json'

require_relative 'my_client'
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
