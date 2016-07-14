# HelloWorldRuby.rb
# generate a real java class for this file like this:
# jrubyc --javac HelloWorldRuby.rb
#   which generates both a HelloWorldRuby.java and a HelloWorldRuby.class file

class HelloWorldRuby

  def self.world
    puts "Hello, World"
  end

  def self.earth
    puts "Hello, Earth"
  end

  def self.moon
    puts "Hello, Moon"
  end

  def self.somebody a_person
    puts "Hello, #{a_person}"
  end

  def self.people persons
    if persons.size > 0
      persons.each do |a_person|
        puts "Hello, #{a_person}"
      end
    else
      puts "Hello, People"
    end
  end


end # class HelloWorldRuby

