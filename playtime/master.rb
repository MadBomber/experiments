#!/usr/bin/env ruby
# frozen_string_literal: true
# encoding: utf-8
##########################################################
###
##  File: master.rb
##  Desc: Master Controller Process for the game
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'awesome_print'
require './lib/battleships.rb'

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

  o.bool    '-b', '--bool',   'example boolean parameter',   default: false
  o.string  '-s', '--string', 'example string parameter',    default: 'IamDefault'
  o.int     '-i', '--int',    'example integer parameter',   default: 42
  o.float   '-f', '--float',  'example float parameter',     default: 123.456
  o.array   '-a', '--array',  'example array parameter',     default: [:bob, :carol, :ted, :alice]
  o.path    '-p', '--path',   'example Pathname parameter',  default: Pathname.new('default/path/to/file.txt')
  o.paths         '--paths',  'example Pathnames parameter', default: ['default/path/to/file.txt', 'file2.txt'].map{|f| Pathname.new f}

end

# Display the usage info
if  ARGV.empty?
  show_usage
  exit
end


# Error check your stuff; use error('some message') and warning('some message')



abort_if_errors


######################################################
# Local methods


######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

ap configatron.to_h  if verbose? || debug?

puts "master is running ..."


game  = Game.new Player, Board
us    = game.player_1
them  = game.player_2


DRb.start_service('druby://localhost:9999', game)
DRb.thread.join



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

