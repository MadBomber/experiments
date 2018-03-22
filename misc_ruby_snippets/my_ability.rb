#!/usr/bin/env ruby -wU
# desc_method.rb
# an idea on how to describe abilities

require 'active_support/all'
require 'awesome_print'

require 'debug_me'
include DebugMe

require 'pathname'
require 'set'

##################################################################
## "Hey, hey we're the monkies and just like monkeying around...."

class Hash

  # searchs a 2-level deep hash looking for entrys (keys) whose sub-key and value
  # are equal to (==) the values given.  If target value is an Array uses
  # Set#subset? to determine equality.
  def where(options={})
    return self if options.empty?  ||  options.class != Hash
    self.select {|key, value|
      result = true
      options.each_pair do |field, field_value|
        if Array == value[field].class
          result &&= Array(field_value).to_set.subset?(value[field].to_set)
        else
          result &&= value[field] == field_value
        end
      end
      result
    }
  end # def where(options)
end # class Hash


class Set

  LIKE_DEFAULT_THRESHOLD = 0.75 # Float between 0.0 and 1.0; like a %

  # Given two sets s1 and s2 tha it is possible
  # for s1.like?(s2) and NOT s2.like?(s1) depending
  # on the relative size of each set.
  def like?(a_set, threshold=LIKE_DEFAULT_THRESHOLD)
    likeness(a_set) >= threshold
  end

  # The size of a_set governs the degree of likeness
  # between any two sets.  The likeness of one set to
  # another is dependant upon the size of the intersection
  # to the size of the parameter set.
  def likeness(a_set)
    return(0.0) if Set != a_set.class || a_set.empty?
    (self & a_set).size.to_f / a_set.size.to_f
  end # def likeness(a_set)
end # class Set


##################################################################
## Here is the guts of the idea with some test examples.  Is this
## level of micro-RBAC worthy to be encapsulated into a Rails Engine?

ABILITIES = Hash.new

def current_user
  rand(42)
end


class ApplicationController
  class << self

    # describe an ability with an optional condition block
    def my_ability(
        ability_identifier,     # required; aka slug
        description='unknown',
        group: nil,
        role:  [],
        &conditional_block
      )

      called_from_parts = caller.first.split(':')
      file_path         = Pathname.new(called_from_parts[0])
      file_line_number  = called_from_parts[1].to_i - 1  # -1 to zero-base the index

      # category_name   = called_from_parts.last[0..-3].gsub('Controller', '')
      category_name     = self.to_s.gsub('Controller', '').singularize

      method_name       = get_next_method_name(file_path, file_line_number)
      defined_at        = caller.first

      roles = Array(role).map{ |role_name|
        String == role_name.class ?
          role_name.downcase.gsub(':', '').to_sym :
          role_name
      }

      if block_given?
        conditional_proc = conditional_block.to_proc
      else
        conditional_proc = Proc.new {true}
      end

      insert_into_abilities(  ability_identifier,
                              category_name,
                              method_name,
                              description,
                              group,
                              roles,
                              defined_at,
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
      a_line.split(/\ +|\(|\{/)[1].to_sym
    end


    # store the gather information into the kernal-level constant
    def insert_into_abilities(  ability_identifier,
                                category_name,
                                method_name,
                                ability_description,
                                group_name,
                                roles,
                                defined_at,
                                condition)

      unless ABILITIES.has_key?(ability_identifier)
        ABILITIES[ability_identifier] = {
          category:   category_name,
          action:     Array(method_name),
          ability:    String(ability_description).humanize.titlecase,
          group:      String(group_name).humanize.titlecase,
          roles:      roles,
          defined_at: defined_at,
          condition:  condition
        }
      else
        # Assumes that duplicate ability_identifier mean the same
        # ability (aka permission)  Values of other parameters on
        # my_ability method call are ignored.  The first occurance
        # within the system sets the values for everything else.
        #
        # We could do checks against these other parameters to see
        # if there is a difference in the previous values as a way
        # of catching potential problems where the duplicate slug
        # was not intended.
        error_count = 0
        if (category_name != ABILITIES[ability_identifier][:category])    ||
           (ABILITIES[ability_identifier][:action].include?(method_name))
          error_count += 1
          puts <<~ERROR

            Warning: Invalid Duplicate Ability Identifier: #{ability_identifier}
                 At: #{defined_at}

              This occurance is being ignored.

              Duplicate abilities are only allowed within the same category
              for different method names (aka actions).

              First occurange was: #{ABILITIES[ability_identifier][:defined_at]}
              Current location is: #{defined_at}

          ERROR
        end

        if error_count > 0
          # raise something is wrong
          return(nil)
        end

        ABILITIES[ability_identifier][:action] << method_name
      end

    end # end def insert_into_abilities( ...
  end # end class << self
end # class ApplicationController



class SomeObjectController < ApplicationController

  my_ability 100, "Vuew a list", group: 100, role: 'viewer'
  my_ability 100, 'invalid non-unique identifier'
  my_ability :index_ability, 'identifiers can be anything for example a symbol'
  my_ability 'index_ability', 'identifiers can be anything for example a string'
  my_ability 100.10, 'identifiers can be anything for example an integer or a float',
    group: 100

  def index
    puts self.name
  end

  my_ability 110, "View a specific", group: 100, role: 'viewer'
  def show
    puts self.name
  end

  my_ability 110.1, "update a specific", role: :updater # strings and symbols are same
  def update
    puts self.name
  end



end # class SomeObjectController < ApplicationController


class AnotherObjectController < ApplicationController

  my_ability 120, "Vuew a list", group: 100
  def index
    puts self.name
  end

  my_ability 130, "View a specific", group: 100
  def show
    puts self.name
  end

  my_ability 140, "delete a specific superuser", role: 'updater'
  my_ability(142, "delete a specific if odd one", group: 140) {|current_user| puts current_user; current_user.odd? }
  my_ability(144, "delete a specific if odd two", group: 140) {|current_user| puts current_user; current_user.odd? }
  def delete
    puts self.name
  end

  my_ability 150, "update a specific superuser", group: 140, role: 'updater'
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


puts "\nThe defined groups are ...."
groups =  ABILITIES.map { |key, value| value[:group].empty? ? nil : value[:group] }.compact.uniq.sort
ap groups


puts "\nWhat permissions are in each group ...."
groups.each do |group|
  puts "Group: #{group} has the following permissions:"
  ap ABILITIES.where(group: group).keys.sort
end


puts "\nWhat standard roles have been defined ...."
roles =  ABILITIES.map { |key, value| value[:roles] }.compact.flatten.uniq.sort
ap roles


puts "\nWhat permissions are associated with the standard roles ...."
roles.each do |role|
  puts "\nFor role: #{role} ..."
  ap ABILITIES.where(roles: role)
end

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

