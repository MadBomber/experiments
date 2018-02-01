#!/usr/bin/env ruby -wKU
# desc_method.rb
# an idea on how to describe abilities
require 'awesome_print'

require 'debug_me'
include DebugMe

require 'pathname'

ABILITIES = Hash.new

class ApplicationController
  class << self

    def desc(a_string)
      called_from_parts = caller.first.split(':')
      file_path         = Pathname.new(called_from_parts[0])
      file_line_number  = called_from_parts[1].to_i - 1  # -1 to zero-base the index
      category_name     = called_from_parts.last[0..-3].gsub('Controller', '')
      method_name = get_next_method_name(file_path, file_line_number)

      insert_into_abilities category_name, method_name, a_string
    end # ebd def desc(a_string)

    ##########################################################
    ## Reserved class methods
    private
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
      method_name = a_line.split(/\ +|\(|\{/)[1]
    end

    def insert_into_abilities(category_name, method_name, description)
      unless ABILITIES.has_key? category_name
        ABILITIES[category_name] = Hash.new
      end
      ABILITIES[category_name][method_name] = description
    end
  end # end class << self
end # class ApplicationController



class SomeObjectController < ApplicationController

  desc "Vuew a list"
  def index
    puts self.name
  end

  desc "View a specific"
  def show
    puts self.name
  end
end # class SomeObjectController < ApplicationController


class AnotherObjectController < ApplicationController

  desc "Vuew a list"
  def index
    puts self.name
  end

  desc "View a specific"
  def show
    puts self.name
  end

  desc "delete a specific"
  def delete
    puts self.name
  end

  desc "update a specific"
  def edit
    puts self.name
  end
end # end class AnotherObjectController < ApplicationController



ap ABILITIES
