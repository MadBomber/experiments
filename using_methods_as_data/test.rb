#!/usr/bin/env ruby
#########################

def one data
	puts "from one -=> #{data}"
end

module Missile
    def self.two data
      puts "from two -=> #{data}"
    end
end

class Radar


  def four data
    puts "from four -=> #{data}"
  end

  def five data
    puts "from five -=> #{data}"
    self.class.three(data)
  end

  class << self
    def three data
      puts "from three -=> #{data}"
    end
  end

end


ah = Hash.new

ah[1] = method(:one)

ah[2] = Missile.method(:two)

ah[3] = Radar.method(:three)

 ah[1].call("a one")

 ah[2].call("and a two")

 ah[3].call("and a three")


 my_radar = Radar.new

 ah[4] = my_radar.method(:four)

 ah[4].call("and a four")


 ah[5] = my_radar.method(:five)

 ah[5].call("getting to three through five")

puts "watch that again ..."

x = 0
ah.each_key do |k|
  x+=1
  ah[k].call(x)
end


puts "\n\n... and now it's time for something completely different."


my_method = def your_method( data ); puts data; end

puts my_method.class
puts my_method

send(my_method, 'better than smalltalk?  no.  but interesting.')
