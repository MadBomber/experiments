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

  def self.three data
    puts "from three -=> #{data}"
  end
  
  def four data
    puts "from four -=> #{data}"
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
 
 
 ah[5] = my_radar.method(:three)
 
 ah[5].call("back to three")

  
  