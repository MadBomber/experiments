#!/usr/bin/env ruby
# frozen_string_literal: true
# encoding: utf-8
##########################################################
###
##  File: tron.rb   --- in honor of the movie
##  Desc: Slave Player to the MCP
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'awesome_print'

require 'cli_helper'
include CliHelper

require 'debug_me'
include DebugMe

require 'drb'


configatron.version = '0.0.1'

HELP = <<EOHELP
Important:

  Put important stuff here.

EOHELP

cli_helper("__file_description__") do |o|

  o.int     '-p', '--player', 'Player Number (1 or 2)',      default: 1

end

# Display the usage info
if  ARGV.empty?
  show_usage
  exit
end


# Error check your stuff; use error('some message') and warning('some message')

unless [1, 2].include? configatron.player
  error "You can only select player 1 or 2"
end

abort_if_errors


######################################################
# Local methods

# A coordination is either "00" .. "99" or
# ("A..J") + ("1".."10") as a symbol
def convert_map_coordinate(map_coordinate)
  coordinate = map_coordinate.to_s # in case it was a symbol
  # converts first character "ABCDEFGHIJ" <=> "0123456789"
  x_axis = coordinate[0]
  y_axis = coordinate[1,2]

  if x_axis.ord < "A".ord
    x_axis = (x_axis.ord + 17).chr  # convert digits to characters
    y_axis = (y_axis.to_i + 1).to_s
    coordinate = (x_axis + y_axis).to_sym
  else
    x_axis = (x_axis.ord - 17).chr  # convert characters to digits
    y_axis = (y_axis.to_i - 1).to_s
    coordinate = x_axis + y_axis
  end
  return coordinate
end

def gui_coordinate?(coordinate)
  String == coordinate.class
end

def game_engine_coordinate?(coordinate)
  Symbol == coordinate.class
end


######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

ap configatron.to_h  if verbose? || debug?

puts "slave is running ..."



DRb.start_service
configatron.game = DRbObject.new_with_uri('druby://localhost:9999')


if 1 == configatron.player
  my_navy = [
    ["00", :vertically, :aircraft_carrier],
    ["11", :vertically, :battleship],
    ["22", :vertically, :cruiser],
    ["33", :vertically, :destroyer],
    ["44", :vertically, :submarine]
  ]
else  # player 2
  my_navy = [
    ["55", :horizontal, :aircraft_carrier],
    ["66", :horizontal, :battleship],
    ["77", :horizontal, :cruiser],
    ["88", :horizontal, :destroyer],
    ["99", :horizontal, :submarine]
  ]
end

my_navy.each do |my_ship_attributes|
  location,
  orientation,
  ship_type     = my_ship_attributes
  begin
    configatron.game.place_ship(
      configatron.player,
      ship_type,
      convert_map_coordinate(location),
      orientation
    )
  rescue => e
    puts e
  end
end


puts
puts "Player ##{configatron.player}'s own view"
puts configatron.game.own_board_view(configatron.player)


until configatron.game.has_winner?
  location = convert_map_coordinate( sprintf("%02i", rand(100)) )
  sleep 0.1 if 1 == rand(2)
  begin
    result = configatron.game.shoot( configatron.player, location)
  rescue
    result = 'dup'
  end
  puts "#{configatron.player}: #{location} #{result}" if %w[hit sunk].include? result.to_s
end

puts
puts "Player ##{configatron.player}'s opponent's view"
puts configatron.game.opponent_board_view( configatron.player )


puts
puts "and the winner is:"

puts configatron.game.winner_name





__END__


Each player can place ships on their own board:

game.player_1.place_ship Ship.battleship, :B4, :vertically

game.player_2.place_ship Ship.cruiser, :G6

Players can shoot at each other's boards:

game.player_1.shoot :C2 #=> :miss
game.player_2.shoot :B4 #=> :hit

Players can view their own boards:

puts game.own_board_view game.player_1

   ABCDEFGHIJ
  ------------
 1|          |1
 2|          |2
 3|          |3
 4| *        |4
 5| B        |5
 6| B        |6
 7| B        |7
 8|          |8
 9|          |9
10|          |10
  ------------
   ABCDEFGHIJ

puts game.own_board_view game.player_2

   ABCDEFGHIJ
  ------------
 1|          |1
 2|  -       |2
 3|          |3
 4|          |4
 5|          |5
 6|      CCC |6
 7|          |7
 8|          |8
 9|          |9
10|          |10
  ------------
   ABCDEFGHIJ

And their opponent's boards:

puts game.opponent_board_view game.player_1

   ABCDEFGHIJ
  ------------
 1|          |1
 2|  -       |2
 3|          |3
 4|          |4
 5|          |5
 6|          |6
 7|          |7
 8|          |8
 9|          |9
10|          |10
  ------------
   ABCDEFGHIJ

puts game.opponent_board_view game.player_2

   ABCDEFGHIJ
  ------------
 1|          |1
 2|          |2
 3|          |3
 4| *        |4
 5|          |5
 6|          |6
 7|          |7
 8|          |8
 9|          |9
10|          |10
  ------------
   ABCDEFGHIJ

Players can sink their opponent's ships:

game.player_2.shoot :B5 #=> :hit
game.player_2.shoot :B6 #=> :hit
game.player_2.shoot :B7 #=> :sunk

And the game can be tested for a winner:

game.has_winner?       #=> true
game.player_1.winner?  #=> false
game.player_2.winner?  #=> true

