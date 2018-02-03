#!/usr/bin/env ruby -wKU
# desc_method.rb
# an idea on how to describe abilities
require 'awesome_print'

require 'debug_me'
include DebugMe

require 'pathname'

ABILITIES = Hash.new

def current_user
  rand(42)
end


class ApplicationController
  class << self

    # describe an ability with an optional condition block
    def my_ability(a_string, &conditional_block)
      called_from_parts = caller.first.split(':')
      file_path         = Pathname.new(called_from_parts[0])
      file_line_number  = called_from_parts[1].to_i - 1  # -1 to zero-base the index
      category_name     = called_from_parts.last[0..-3].gsub('Controller', '')
      method_name = get_next_method_name(file_path, file_line_number)

      if block_given?
        conditional_proc = conditional_block.to_proc
      else
        conditional_proc = Proc.new {true}
      end

      insert_into_abilities(category_name, method_name, a_string, conditional_proc)
    end # end def my_ability(a_string, &conditional_block)


    ##########################################################
    ## Reserved class methods
    private

    # Find the method name to which this ability applies
    # Assumes that the method name follows "def" on the same line
    def get_next_method_name(a_path, a_line_number)
      lines = a_path.read.split("\n")
      called_from_line  = lines[a_line_number]
      found_def         = false
      line_number       = a_line_number
      a_line = ""
      while !found_def do
        line_number += 1
        a_line = lines[line_number].strip
        found_def = a_line.start_with? 'def'
      end
      a_line.split(/\ +|\(|\{/)[1]
    end


    # store the gather information into the kernal-level constant
    def insert_into_abilities(  category_name,
                                method_name,
                                ability_description,
                                condition)
      unless ABILITIES.has_key? category_name
        ABILITIES[category_name] = Hash.new
      end
      if ABILITIES[category_name].has_key? method_name
        ABILITIES[category_name][method_name] << {
          ability:    ability_description,
          condition:  condition
        }
      else
        ABILITIES[category_name][method_name] = [{
          ability:    ability_description,
          condition:  condition
        }]
      end
    end # end def insert_into_abilities( ...
  end # end class << self
end # class ApplicationController



class SomeObjectController < ApplicationController

  my_ability "Vuew a list"
  def index
    puts self.name
  end

  my_ability "View a specific"
  def show
    puts self.name
  end
end # class SomeObjectController < ApplicationController


class AnotherObjectController < ApplicationController

  my_ability "Vuew a list"
  def index
    puts self.name
  end

  my_ability "View a specific"
  def show
    puts self.name
  end

  my_ability "delete a specific superuser"
  my_ability("delete a specific if odd one") {|current_user| puts current_user; current_user.odd? }
  my_ability("delete a specific if odd two") {|current_user| puts current_user; current_user.odd? }
  def delete
    puts self.name
  end

  my_ability "update a specific superuser"
  my_ability("update a specific if even one") {|current_user| puts current_user; current_user.even? }
  my_ability("update a specific if even two") {|current_user| puts current_user; current_user.even? }
  def edit
    puts self.name
  end
end # end class AnotherObjectController < ApplicationController


puts "All Abilities ..."
ap ABILITIES

puts "Permissions for AnotherObject's edit action ..."
ap ABILITIES['AnotherObject']['edit']

ABILITIES['AnotherObject']['edit'].each do |a_desc_hash|
  puts a_desc_hash[:ability]
  puts a_desc_hash[:condition].call(current_user)
end
