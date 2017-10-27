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


module ActiveRecord
  class Schema
    class << self

      def define(a_hash, &block)
        migration_version = a_hash[:version].to_s
        debug_me{:migration_version}
        d = Define.new(migration_version)
        d.instance_eval(&block)
      end

    end # class << self
  end # class Schema
end # module ActiveRecord


class Define

  def initialize(migration_version)
    @migration_version = migration_version
  end


  def create_table(*args, &block)
    debug_me{:args}
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
    # NOOP
  end


  def add_foreign_key(*args)
    table_name = args.shift
    t = Table.new(table_name)

    # TODO: need to get the singular version of the table name
    reference_field_name = args.shift + '_id'

    t.reference(reference_field_name)

    debug_me{[ :table_name, :reference_field_name, :args]}
    unless $tables[table_name].has_key?(:foreign_key)
      $tables[table_name][:foreign_key] = [ [reference_field_name, args] ]
    else
      $tables[table_name][:foreign_key] << [reference_field_name, args]
    end
  end

end # class Define


class Table
  def initialize(*args)
    puts "="*42
    @table_name = args.shift
    $tables[@table_name] = args.first # SMELL: assumes only a hash follows
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

        unless $columns.has_key?(@column_name)
          $columns[@column_name] = [ [@table_name, args] ]
        else
          $columns[@column_name] << [@table_name, args]
        end

        yield if block_given?
        self
      end
    EOM
  end



end # class Table


at_exit do
  puts "Data Dictionary"
  ap $tables
  ap $columns
end

__END__
      %w[
          enable_extension define create_table add_index add_foreign_key
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
          def #{dsl_method_name}(*args, &block)
            debug_me{:args}
            yield(self) if block_given?
            self
          end
        EOM
      end


