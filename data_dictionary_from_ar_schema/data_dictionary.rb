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

require 'active_support/all'


$schema_version = "The date of the last migration"
$tables         = Hash.new
$columns        = Hash.new


module ActiveRecord
  class Schema
    class << self

      def define(a_hash, &block)
        migration_version = a_hash[:version].to_s
        d = Define.new(migration_version)
        d.instance_eval(&block)
      end

    end # class << self
  end # class Schema
end # module ActiveRecord


class Define

  def initialize(migration_version)
    $schema_version = migration_version
  end


  def create_table(*args, &block)
    t = Table.new(*args)
    t.instance_eval(&block)
  end


  def add_index(*args)
    table_name = args.shift

    unless $tables[table_name].has_key?(:indexed_by)
      $tables[table_name][:indexed_by] = [args.flatten.shift]
    else
      $tables[table_name][:indexed_by] << args.flatten.shift
    end
  end


  def enable_extension(*args)
    # NOOP - don't care about what extensions are installed
  end


  def add_foreign_key(*args)
    table_name = args.shift
    t = Table.new(table_name)

    associated_table_name = args.shift

    reference_field_name = associated_table_name.singularize + '_id'

    t.reference(reference_field_name)

    unless $tables[table_name].has_key?(:foreign_key)
      $tables[table_name][:foreign_key] = [ [reference_field_name, args] ]
    else
      $tables[table_name][:foreign_key] << [reference_field_name, args]
    end

    unless $tables[table_name].has_key?(:associated_with)
      $tables[table_name][:associated_with] = [ associated_table_name ]
    else
      $tables[table_name][:associated_with] << associated_table_name
    end

    unless $tables[associated_table_name].has_key?(:associated_with)
      $tables[associated_table_name][:associated_with] = [ table_name ]
    else
      $tables[associated_table_name][:associated_with] << table_name
    end



  end # def add_foreign_key(*args)

end # class Define


class Table
  def initialize(*args)
    @table_name = args.shift
    unless args.empty?
      $tables[@table_name] = args.first # SMELL: assumes only a hash follows
    end
  end

  %w[
      string
      datetime
      text
      boolean
      integer
      inet
      json
      date
      reference
  ].each do |dsl_method_name|
    eval <<~EOM
      def #{dsl_method_name}(*args, &block)
        @column_name = args.shift
        @data_type   = "#{dsl_method_name}"

        unless $columns.has_key?(@column_name)
          $columns[@column_name] = [ [@table_name, @data_type, args] ]
        else
          $columns[@column_name] << [@table_name, @data_type, args]
        end

        yield if block_given?
        self
      end
    EOM
  end



end # class Table


def table_report
  puts "\n\n## Database Tables"
  puts <<~EndOfHeader

    | Table Name | Indexed By | Associated With |
    | ---------- | ---------- | --------------- |
  EndOfHeader

  keys = $tables.keys.sort
  keys.each do |table_name|
    puts "| #{table_name} | #{$tables[table_name][:indexed_by].join(', ')} | #{$tables[table_name][:associated_with].join(', ')} |"
  end

  puts "\n\n"

end

class String
  def join(*args)
    self
  end
end


class NilClass
  def join(*args)
    'N/A'
  end
  def has_key?(*args)
    false
  end
  def [](*args)
    'N/A'
  end
end


def column_report
  puts "\n\n## Column Definitions"
  puts <<~EndOfHeader

    | Column Name | Table Name | Data Type | Qualifiers |
    | ----------- | ---------- | --------- | ---------- |
  EndOfHeader

  keys = $columns.keys.sort

  keys.each do |key|
    tables = $columns[key].each do |table|
      table_name  = table.shift
      data_type   = table.shift
      other_stuff = table.flatten
      other_stuff = other_stuff.empty? ? '' : other_stuff.shift
      puts "| #{key} | #{table_name} | #{data_type} | #{other_stuff} |"
    end
  end

  # ap $columns['visn_id']
  # ap $columns['xml']

end


at_exit do
  puts "# Data Dictionary"
  puts <<~EndOfHeader

    This report is auto-generated from the file 'db/schema.rb'

    Report Date:    #{Date.today}
    Last Migration: #{$schema_version}

  EndOfHeader

  table_report
  column_report
end

