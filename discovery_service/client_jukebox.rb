#!/usr/bin/env ruby
# Tabletop client

require 'drb'

class Song
  include DRbUndumped

  def to_s
    "#{title} by #{artist}"
  end
end

DRb.start_service
jukebox = DRbObject.new nil, ARGV.shift

loop do
  puts "Select a song:"

  jukebox.songs.each_with_index do |s, i|
    puts "#{i + 1}) #{s}"
  end

  print "> "
  STDOUT.flush

  index = gets.to_i

  begin
    jukebox.play(index)
    puts "Playing: #{jukebox.songs[index]}"
  rescue
    puts "Invalid selection"
    retry
  end
end
