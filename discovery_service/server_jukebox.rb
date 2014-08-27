#!/usr/bin/env ruby -w
# Jukebox Server

require 'drb'

Song = Struct.new 'Song', :title, :artist

class Song
  def to_s
    "#{title} by #{artist}"
  end
end

class Jukebox
  attr :songs
  
  def initialize(songs)
    @songs = songs
  end
  
  def play(index)
    puts "playing #{@songs[index]}"
  end
end

songs = [
  Song.new("Amish Paradise", "Weird Al"),
  Song.new("Eat it", "Weird Al")
]

DRb.start_service nil, Jukebox.new(songs)
puts DRb.uri

DRb.thread.join