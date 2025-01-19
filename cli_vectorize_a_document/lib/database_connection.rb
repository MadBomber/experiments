# lib/database_connection.rb

require 'amazing_print'
require 'debug_me'
include DebugMe
require 'matrix'

require 'pg'
require 'neighbor'
require 'active_record'
require 'active_model'
require 'active_support'
require 'yaml'

require_relative 'models'

class DatabaseConnection
  def self.setup
    config = load_configuration
    ActiveRecord::Base.establish_connection(config)
  end

  def self.load_configuration
    file = File.join(__dir__, '../config/database.yml')
    YAML.load_file(file, aliases: true)[ENV['RACK_ENV'] || 'development']
  end
end

DatabaseConnection.setup

DB = ActiveRecord::Base.connection

debug_me{[ 'DB' ]}

# conn = PG.connect(dbname: "dv_development")

# registry = PG::BasicTypeRegistry.new
# Pgvector::PG.register_vector(registry)
# conn.type_map_for_results = PG::BasicTypeMapForResults.new(conn, registry: registry)

# Optional: Verify the registration
# if conn.type_map_for_results.type_for_column('your_table_name', 'your_vector_column_name')
#   puts 'Vector type registered successfully.'
# else
#   puts 'Failed to register vector type.'
# end

