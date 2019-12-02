# table_read/talent_pool.rb

require_relative './actor'
require_relative './country_language_map'

class TalentPool
  attr_accessor :cast
  attr_accessor :cast_language

  def initialize
    @pool = []

    results = `say -v '?'`.split("\n")

    results.each do |entry|
      add_actor_to_pool(entry)
    end
  end

  def show
    @pool.each { |actor| puts; actor.show }
    nil
  end

  def add_actor_to_pool(voice_info)
    parts     = voice_info.split('#')
    test_line = parts.last

    stage_name, type        = parts.first.split()
    lang_code, country_code = type.split('_')

    @pool << Actor.new( stage_name,
                        to_language(lang_code),
                        to_country(country_code),
                        test_line
                      )
  end

  def languages
    @pool.map{|entry| entry.language}.uniq.sort
  end

  def countries
    @pool.map{|entry| entry.country}.uniq.sort
  end

  def who_speak a_language
    @pool.select{|entry| entry.language.downcase == a_language.downcase}
  end

  def from_country a_country
    @pool.select{|entry| entry.country.downcase == a_country.downcase}
  end


  def auto_cast(characters, language='English')
    @cast_language  = language
    @cast = Hash.new
    parts = characters.dup
    parts << 'action' unless parts.include?('action')

    actors = who_speak(@cast_language).sample(parts.size)

    parts.each do |character|
      @cast[character] = actors.shift
    end

    return @cast
  end


  def assign_cast(a_hash)
    @cast = {}
    a_hash.each_pair do |character, actor_name|
      @cast[character] = @pool.select{|actor| actor.name == actor_name }.first
    end
  end


  def save_cast(config_path=nil)
    @cast.each_pair do |character, actor|
      puts "#{character}: #{actor.name}"
    end
    return nil
  end


  def recast
    actors = who_speak(@cast_language).sample(@cast.keys.size)

    @cast.keys.each do |character|
      @cast[character] = actors.shift
    end

    return @cast
  end


  def screen_test(scene)
    scene.each do |entry|
      character = entry.keys.first
      line      = entry[character]

      puts "\n#{character} - #{line}"

      @cast[character].say(line)
    end
  end

  private

  def to_country(a_string)
    entry = CountryLanguageMap['countries'].fetch(a_string, nil)
    result = entry.nil? ? 'unknown' : entry['name']
    return result
  end

  def to_language(a_string)
    entry = CountryLanguageMap['languages'].fetch(a_string, nil)
    result = entry.nil? ? 'unknown' : entry['english_name']
    return result
  end
end
