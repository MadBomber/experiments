#!/usr/bin/env ruby
# test.rb

ENV['RACK_ENV'] = 'production'

require_relative 'lib/database_connection'

debug_me{[
  'DB'
]}



# Fetches and prints the names of all tables in the database
def list_table_names(db_connection:)
  # Assuming the connection has a method to execute a SQL query
  query = "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';"

  # Execute the query and fetch results
  table_names = db_connection.execute(query).map { |row| row['table_name'] }

  # Print out the table names
  table_names.each { |name| puts name }
end

# Main execution
if __FILE__ == $PROGRAM_NAME
  # Call the method to list table names
  list_table_names(db_connection: DB)
end

