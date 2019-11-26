# table_read/spec_script.rb

require_relative './db_access'


# Provides access to the contents of
# a ScenArtist (Scene Artist) script
# which stored in an SQLite database.
class SpecScript

  attr_accessor :raw
  attr_accessor :script

  attr_accessor :characters
  attr_accessor :scenes

  def initialize(a_file_path)
    load_script(a_file_path)
    collect_scenes
    collect_characters
  end

  def load_script(file_path)
    Database.setup(file_path)

    @raw    = Nokogiri.parse Scenario.find(1).text
    @script = @raw.elements[0]
  end


  def collect_scenes
    @scenes       = []
    scene_number  = 0

    @script.xpath('//scene_heading').each do |e|
      scene_number += 1
      @scenes << scene_number.to_s + " - " + e.children[1].children[0].to_str
    end

    return @scenes
  end


  def collect_characters
    @characters = []

    @script.xpath('//character').each do |e|
      character_name = e.children[1].children[0].to_str
      @characters << character_name unless @characters.include? character_name
    end

    return @characters
  end


  def display_script
    scene_number = 0

    @script.elements.each do |e|
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
    end # @script.elements.each do |e|

    return nil
  end
end # class SpecScript
