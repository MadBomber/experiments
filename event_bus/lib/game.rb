# encoding: utf-8
# frozen_string_literal: true
##########################################################
###
##  File: game.rb.rb
##  Desc: Generic game model
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

# A generic/base Game model
class Game
  MINIMUM_BET_SIZE = 100.0
  KEEP_PLAYING_RESPONSES = %w[y yes yep yea sure ok go]

  attr_reader   :players


  def initialize(players)
    @players = Array(players)
    event :game_initialized, game_name: self.class.to_s
  end

  def play
    begin
      event :start_game_turn, game_name: self.class.to_s
      play_one_turn
    end while keep_playing?

    message "tankz fur playing.  Come back soon when you want to lose some more."
  
    event :game_terminated, game_name: self.class.to_s
  end

  def play_one_turn
    message "... and we are playing ..."
    wager = ask("Place your bet?").to_f.abs

    spinning

    @players[0].lose(wager)
  end

  def keep_playing?
    print "Would you like to continue? "
    KEEP_PLAYING_RESPONSES.include?(STDIN.gets.chomp.downcase)
  end


  def self.choose_a_game
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end
 

  ################################################
  private



end # class Game

# SMELL: this may not be necessary since require_all 'lib'
#        was used in the main sinsim.rb file
require_relative 'game/black_jack.rb'
require_relative 'game/craps.rb'
require_relative 'game/poker.rb'
require_relative 'game/roulette.rb'
require_relative 'game/slot.rb'
require_relative 'game/texas_holdem.rb'
require_relative 'game/war.rb'

