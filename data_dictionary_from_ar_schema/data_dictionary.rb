#!/usr/bin/env ruby
########################################################
###
##  File: data_dictionary.rb
##  Desc: Process an active record schema.rb file to producte a
##        data dictionary report showing all tables in the database with
##        their associations and all columns with their data types.
#

require 'debug_me'
include DebugMe

require 'awesome_print'

$tables   = Hash.new
$columns  = Hash.new

%w[
  enable_extension create_table add_index add_foreign_key
  string
  datetime
  text
  boolean
  integer
  inet
  json
  date
].each do |dsl_method_name|
  eval <<~EOM
    def self.#{dsl_method_name}(*args, &block)
      debug_me{:args}
      yield block if block_given?
    end
  EOM
end





module ActiveRecord
  class Schema

    %w[
      define
    ].each do |dsl_method_name|
      class_eval <<~EOM
        def self.#{dsl_method_name}(*args, &block)
          debug_me{:args}
          yield block if block_given?
        end
      EOM
    end

    class << self

    end # class << self
  end # class Schema
end # module ActiveRecord

at_exit do
  puts "Data Dictionary"
  ap $tables
  ap $columns
end
