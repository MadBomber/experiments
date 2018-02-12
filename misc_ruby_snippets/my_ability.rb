#!/usr/bin/env ruby -wU
# desc_method.rb
# an idea on how to describe abilities
require 'awesome_print'

require 'debug_me'
include DebugMe

require 'pathname'

class Hash
  def where(options={})
    return self if options.empty?  ||  options.class != Hash
    self.select {|key, value|
      result = true
      options.each_pair do |field, field_value|
        result &&= value[field] == field_value
      end
      result
    }
  end # def where(options)
end


ABILITIES = Hash.new

def current_user
  rand(42)
end


class ApplicationController
  class << self

    # describe an ability with an optional condition block
    def my_ability(ability_unique_identifier, description, &conditional_block)

      called_from_parts = caller.first.split(':')
      file_path         = Pathname.new(called_from_parts[0])
      file_line_number  = called_from_parts[1].to_i - 1  # -1 to zero-base the index
      category_name     = called_from_parts.last[0..-3].gsub('Controller', '')
      method_name       = get_next_method_name(file_path, file_line_number)

      if block_given?
        conditional_proc = conditional_block.to_proc
      else
        conditional_proc = Proc.new {true}
      end

      insert_into_abilities(  ability_unique_identifier,
                              category_name,
                              method_name,
                              description,
                              conditional_proc)
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
    def insert_into_abilities(  ability_unique_identifier,
                                category_name,
                                method_name,
                                ability_description,
                                condition)

      unless ABILITIES.has_key?(ability_unique_identifier)
        ABILITIES[ability_unique_identifier] = {
          category:   category_name,
          action:     method_name,
          ability:    ability_description,
          condition:  condition
        }
      else
        error_msg = "Non-unique ability identifier #{ability_unique_identifier} in #{category_name} at #{method_name} - #{ability_description}"
        puts "\n** ERROR ** " + error_msg + "\n\n"
        #raise error_msg
      end

    end # end def insert_into_abilities( ...
  end # end class << self
end # class ApplicationController



class SomeObjectController < ApplicationController

  my_ability 100, "Vuew a list"
  my_ability 100, 'invalid non-unique identifier'
  my_ability :index_ability, 'identifiers can be anything for example a symbol'
  my_ability 'index_ability', 'identifiers can be anything for example a string'
  my_ability 100.10, 'identifiers can be anything for example an integer or a float'

  def index
    puts self.name
  end

  my_ability 110, "View a specific"
  def show
    puts self.name
  end
end # class SomeObjectController < ApplicationController


class AnotherObjectController < ApplicationController

  my_ability 120, "Vuew a list"
  def index
    puts self.name
  end

  my_ability 130, "View a specific"
  def show
    puts self.name
  end

  my_ability 140, "delete a specific superuser"
  my_ability(142, "delete a specific if odd one") {|current_user| puts current_user; current_user.odd? }
  my_ability(144, "delete a specific if odd two") {|current_user| puts current_user; current_user.odd? }
  def delete
    puts self.name
  end

  my_ability 150, "update a specific superuser"
  my_ability(152, "update a specific if even one") {|current_user| puts current_user; current_user.even? }
  my_ability(154, "update a specific if even two") {|current_user| puts current_user; current_user.even? }
  def edit
    puts self.name
  end
end # end class AnotherObjectController < ApplicationController


puts "\nAll Abilities ..."
ap ABILITIES

puts "\nPermissions for AnotherObject's edit action ..."
ap ABILITIES.where category: 'AnotherObject', action: 'edit'


puts "\nCalling the conditional proc for AnotherObject's edit action ..."
ABILITIES.where(category: 'AnotherObject', action: 'edit').each do |key, value|
  print key
  puts ' -- ' + value[:ability]
  puts value[:condition].call(current_user)
end


puts "\nList of categories ..."
ap ABILITIES.map { |key, value| value[:category] }.uniq.sort


puts "\nList of actions for AnotherObject ..."
ap ABILITIES.where(category: 'AnotherObject').map { |key, value| value[:action] }.uniq.sort

##########################################################


class Role
  attr_accessor :name
  def initialize(name, permissions={})
    @name = name
    @permissions = permissions
  end

  def has_permission?(permission_id)
    @permissions.has_key? permission_id
  end
end # class Role

editor  = Role.new( 'editor', ABILITIES.where(action: 'edit') )
guest   = Role.new( 'guest',  ABILITIES.where(action: 'index') )

ROLES = { editor: editor, guest: guest }

print "\nCan an editor do 100? "
puts editor.has_permission? 100

print "Can an editor do 150? "
puts editor.has_permission? 150


###########################################
class User
  def initialize(name, roles=[])
    @name = name
    @roles = roles.map{|r| r.to_sym}
  end

  def has_role?(role_name)
    role_name = role_name.to_sym if String == role_name.class
    @roles.include? role_name
  end

  def has_permission?(perm_id)
    result = false
    @roles.each do |role_name|
      result ||= ROLES[role_name].has_permission? perm_id
    end
    result
  end
end # class User

billy = User.new 'billy', [editor.name, :guest]

print "\nIs billy an editor? "
puts billy.has_role? 'editor'

print "Is billy still an editor? "
puts billy.has_role? :editor

print "Is billy a guest? "
puts billy.has_role? :guest


print "Can billy do 100? "
puts billy.has_permission? 100

print "Can billy do 150? "
puts billy.has_permission? 150



