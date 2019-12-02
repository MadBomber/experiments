# table_read/spec_script.rb

require 'pathname'

require_relative './db_access'
require_relative './talent_pool'


# Provides access to the contents of
# a ScenArtist (Scene Artist) script
# which stored in an SQLite database.
class SpecScript

  attr_accessor :raw
  attr_accessor :script

  attr_accessor :characters
  attr_accessor :scene_names

  # a reorganized array of hashes
  # each entry in the array is a scene
  # a scene is a hash
  # { scene_heading: 'text', says: [] }
  # eachs says element is an array of hashes
  # { 'action | character name' => 'text'}
  attr_accessor :scenes

  attr_accessor :cast

  attr_accessor :talent

  def initialize(a_file_path)
    @db_path  = a_file_path

    load_script(a_file_path)
    collect_scene_names
    collect_characters
    assign_cast(a_file_path)
    build_scenes
  end


  def table_read(scene_number=nil)
    raise "Bas Scebe Bynber.  Must be between 1 and #{@scenes.size}" unless scene_number.nil? || (1..@scenes.size).include?(scene_number)

    debug_me{[ 'scene_number.class' ]}

    case scene_number.class.to_s
    when 'Integer'
      sn = scene_number - 1
      debug_me{[ '@scenes[sn][:says]', :sn ]}
      @talent.screen_test(@scenes[sn][:says])
    when 'Range'
      scene_number.each do |sn|
        @talent.screen_test(@scenes[sn-1][:says])
      end
    when 'NilClass'
      @scenes.size.times do |sn|
        @talent.screen_test(@scenes[sn][:says])
      end
    end
    return nil
  end


  def assign_cast(ss_file_path)
    @cast     = {}
    @talent   = ::TalentPool.new
    cast_path = ss_file_path.parent + ss_file_path.basename.to_s.gsub('kitsp','cast')

    if cast_path.exist?
      @cast = YAML.load cast_path.read
      @talent.assign_cast @cast
    else
      @talent.auto_cast @characters
      @talent.cast.each_pair do |character, actor|
        @cast[character] = actor.name
      end
    end

    return @cast
  end


  def save_script_as_xml

    dir   = Pathname.pwd # @db_path.parent
    base  = 'script' # @db_path.basename.to_s

    xml_path = dir + "#{base}.xml"

    xml_path.write @xml
  end


  def load_script(file_path)
    Database.setup(file_path)

    @scenarios  = Scenario.all
    @xml        = @scenarios.first.text
    @raw        = Nokogiri.parse @xml
    @script     = @raw.elements[0]
  end


  def collect_scene_names
    sn            = 0 # scene)number
    @scene_names  = @script.xpath('//scene_heading/v').map{|e| "#{sn+=1} - "+e.text.strip}
  end


  def collect_characters
    @characters =  @script.xpath('//character/v').map{|e| e.text.gsub(/\(.+\)/,'').strip.upcase}.uniq
    @characters << 'action'
  end


  def add_scene(e)
    scene_heading = "#{@scenes.size + 1} - " + e.xpath('./v').text.strip
    @scenes << {
      'screen_header' => scene_heading,
      says: [
        {
          'action' => "Scene Number #{scene_heading}"
        }
      ]
    }
  end


  # returns two index.  The first is the scene_number(sn).
  # The second index is the scene_says_number(ssn).
  # e.g. @scenes[sn][:says][ssn]
  def get_scene_indexes
    sn  = @scenes.size - 1
    ssn = @scenes[sn][:says].size - 1
    return [sn, ssn]
  end


  def add_action(e)
    sn, ssn  = get_scene_indexes

    action = e.xpath('./v').text.strip

    if !@scenes[sn][:says].empty? && @scenes[sn][:says].last.has_key?('action')
      prev_action = @scenes[sn][:says][ssn]['action']
      @scenes[sn][:says][ssn]['action'] = prev_action + "\n" + action
    else
      @scenes[sn][:says] << {
        'action' => action
      }
    end

  end


  def add_character(e)
    @current_character = e.xpath('./v').text.strip.upcase
    if @current_character.include?('(')
      sn, ssn       = get_scene_indexes
      parenthetical = @current_character.match(/(\(.+\))/)[1]
      @current_character.gsub!(/\(.+\)/,'').strip!
      @scenes[sn][:says] << {
        'action' => sayable_parenthetical(parenthetical)
      }
    end

    return @current_character
  end


  def sayable_parenthetical(parenthetical)
    case parenthetical
    when '(O.S)', '(O. S.)'
      'from off screen'
    when "(CONT'D)", "(CON'T)"
      "#{@current_character} continues speaking"
    else
      parenthetical
    end
  end

  def add_dialog(e)
    sn, ssn  = get_scene_indexes

    dialog = e.xpath('./v').text.strip

    if @current_character == @scenes[sn][:says][ssn].keys.first
      @scenes[sn][:says][ssn][@current_character] += dialog
    else
      @scenes[sn][:says] << {
        @current_character => dialog
      }
    end
  end


  def build_scenes
    @scenes       = []
    scene_number  = -1

    @script.elements.each do |e|
      if 'scene_heading' == e.name
        add_scene(e)
      elsif 'action' == e.name
        add_action(e)
      elsif 'parenthetical' == e.name
        add_action(e)
      elsif 'character' == e.name
        add_character(e)
      elsif 'dialog' == e.name
        add_dialog(e)
      else
        # do nothing
      end

    end
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

__END__

The ScenArtist XML layout is simplistic, linear and flat.
This is found in the Scenario table, text column.

<?xml version="1.0"?>
<scenario version="1.0">
  <scene_heading uuid="{000000-0000000-000000}">
    <v>
      <![CDATA[INT. COMPUTER ROOM]]>
    </v>
  </scene_heading>
  <action>
    <v>
      <![CDATA[The writer has just installed and activateed the new script editor.]]>
    </v>
  </action>
  <character>
    <v>
      <![CDATA[WRITER]]>
    </v>
  </character>
  <dialog>
    <v>
      <![CDATA[What do I do now?]]>
    </v>
  </dialog>
  <character>
    <v>
      <![CDATA[DIGITAL ASSISTANT]]>
    </v>
  </character>
  <dialog>
    <v>
      <![CDATA[You write your screen play.]]>
    </v>
  </dialog>
  <character>
    <v>
      <![CDATA[WRITER]]>
    </v>
  </character>
  <dialog>
    <v>
      <![CDATA[How do I do that? ]]>
    </v>
  </dialog>
  <parenthetical>
    <v>
      <![CDATA[(beat)]]>
    </v>
  </parenthetical>
  <dialog>
    <v>
      <![CDATA[I have no ideas.]]>
    </v>
  </dialog>
  <character>
    <v>
      <![CDATA[DIGITAL ASSISTANT]]>
    </v>
  </character>
  <dialog>
    <v>
      <![CDATA[Sounds like a personal problem.]]>
    </v>
  </dialog>
  <character>
    <v>
      <![CDATA[WRITER]]>
    </v>
  </character>
  <dialog>
    <v>
      <![CDATA[You are not being very helpful.]]>
    </v>
  </dialog>
  <character>
    <v>
      <![CDATA[DIGITAL ASSISTANT]]>
    </v>
  </character>
  <dialog>
    <v>
      <![CDATA[If you wanted a helpful assistant you should have bought a macintosh.]]>
    </v>
  </dialog>
  <scene_heading uuid="{60585259-47bf-43c1-a074-0cd9f8a4a53d}">
    <v>
      <![CDATA[INT. COMPUTER ROOM]]>
    </v>
  </scene_heading>
  <action>
    <v>
      <![CDATA[Days have passed. The writer appears to be in the same cloths. Paper plates with half-eaten food items and pizza boxes all visible all over the office.]]>
    </v>
  </action>
  <character>
    <v>
      <![CDATA[WRITER]]>
    </v>
  </character>
  <dialog>
    <v>
      <![CDATA[That's the end. 130 pages of the best stuff I have ever done. I could not have done it without your help.]]>
    </v>
  </dialog>
  <character>
    <v>
      <![CDATA[DIGITAL ASSISTANT]]>
    </v>
  </character>
  <dialog>
    <v>
      <![CDATA[Its a good thing you did have a macintosh.]]>
    </v>
  </dialog>
</scenario>

