#!/usr/bin/env ruby
# table/_read/db_access.rb
# The free ScenArtist (aka Scene Artist) software stores its data
# in an SQLite database.

require 'active_record'
require 'awesome_print'

require 'debug_me'
include DebugMe

require 'logger'
require 'nokogiri'
require 'pathname'
require 'sqlite3'

class Database
  def self.setup(db_path)
    # ActiveRecord::Base.logger = Logger.new

    connection_options = {
        :adapter  => 'sqlite3',
        :database => db_path,
        :pool     => 5,
        :timeout  => 25000,
    }

    ActiveRecord::Base.configurations = {
        :production => connection_options,
    }

    ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[:production])
  end
end

########################################################
## Models

class Scenario < ActiveRecord::Base
  self.table_name = 'scenario'
end


at_exit do
  ActiveRecord::Base.connection_pool.release_connection
end

__END__

#########################
## Main for testing

HOME_DIR  = Pathname.new ENV['HOME']
DOC_DIR   = HOME_DIR + 'Documents'

db_path   = DOC_DIR + 'my_new_screenplay.kitsp'

Database.setup(db_path)

scenario = Scenario.find(1)

# ap scenario

doc = Nokogiri.parse scenario.text

script = doc.elements[0]

scene_number = 0

script.elements.each do |e|
  if 'character' == e.name
    character_name = e.children[1].children[0].to_str
    printf "\ncharacter: %s\n", character_name
  elsif 'dialog' == e.name
    dialog =  e.children[1].children[0].to_str
    printf "\ndialog: %s\n", dialog
  elsif 'action' == e.name
    action =  e.children[1].children[0].to_str
    printf "\naction: %s\n", action
  elsif 'parenthetical' == e.name
    parenthetical = e.children[1].children[0].to_str
    printf "\nparenthetical: %s\n", parenthetical
  elsif 'scene_heading' == e.name
    scene_number += 1
    scene_heading = e.children[1].children[0].to_str
    printf "\nscene: SN-%d - %s\n", scene_number, scene_heading
  else
    puts
    puts e.name
    ap e
  end
end

# Get a list of characters
characters = []
script.xpath('//character').each do |e|
  character_name = e.children[1].children[0].to_str
  characters << character_name unless characters.include? character_name
end

ap characters


number_of_scenes = script.xpath('//scene_heading').size

puts number_of_scenes

__END__
