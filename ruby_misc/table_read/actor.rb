# table_read/actor.rb

class Actor
  attr_accessor :name, :language, :country
  def initialize(name, language, country, greeting='hello, I am happy to be here.')
    @name     = name
    @language = language
    @country  = country
    @greeting = greeting

    @speak = "say -v #{@name}"
  end

  def show
    puts "#{name} speaks #{@language} from #{@country} #{@greeting}"
    nil
  end

  def say(a_string)
    a_line = make_speakable(a_string)
    `#{@speak} "#{a_line}"`
  end

  def make_speakable(a_string)
    a_string.gsub("\n",' ')
            .squeeze(' ')
            .gsub('(beat)', ',,,')
            .gsub('-', ',')
            .gsub('(','')
            .gsub(')','')
            # .gsub("'","''")

  end
end
