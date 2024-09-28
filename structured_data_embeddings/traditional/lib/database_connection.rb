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
require 'optparse'

require_relative 'my_client'
require_relative 'models'

class DatabaseConnection
  class << self
    attr_accessor :values_column

    def setup(options = {})
      @values_column = options[:values_column] || 'content'
      config = load_configuration
      ActiveRecord::Base.establish_connection(config)
    end

    def load_configuration
      file = File.join(__dir__, '../db/database.yml')
      yaml_content = ERB.new(File.read(file)).result  # Process the YAML through ERB
      YAML.safe_load(yaml_content, aliases: true)[ENV['RACK_ENV'] || 'development']
    end

    def parse_options
      options = {}
      OptionParser.new do |opts|
        opts.banner = "Usage: ruby your_script.rb [options]"
        opts.on("-v", "--values-column COLUMN", "Specify the column to use for values (content or data)") do |column|
          options[:values_column] = column if ['content', 'data'].include?(column)
        end
      end.parse!
      options
    end
  end
end

options = DatabaseConnection.parse_options
DatabaseConnection.setup(options)

DB = ActiveRecord::Base.connection
