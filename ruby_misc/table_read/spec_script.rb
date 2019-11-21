# table_read/spec_script.rb

class SpecScript
  attr_accessor :raw
  attr_accessor :tab_stops
  attr_accessor :characters

  def initialize(a_file_path=Pathname.new('./sample_scripts/jaws.txt'))
    @tab_stops  = {}
    @characters = []
    @raw          = a_file_path.read.split("\n")

    collect_tab_stops
    collect_characters
  end

  def collect_tab_stops
    line = 0
    @raw.each do |a_line|
      key = indentation(a_line)
      if @tab_stops.has_key? key
        @tab_stops[key][:count] += 1
        @tab_stops[key][:lines] << line
      else
        @tab_stops[key] = {count: 1, lines:[]}
      end
      line += 1
    end
    return @tab_stops
  end

  def collect_characters(from_tab_stop=11)
    raise 'Not a valid tab_stop' unless tab_stops.has_key? from_tab_stop

    tab_stops[from_tab_stop][:lines].each do |line_number|
      character = strip_direction(raw[line_number]).strip
      next unless character.upcase == character
      next if character.empty?
      @characters << character
    end

    @characters.uniq!
  end

  def strip_direction(a_string)
    a_string.gsub(/\(.*\)/, '')
            .gsub('THE END', '')
  end

  def indentation(a_string)
    a_string[/\A */].size
  end
end