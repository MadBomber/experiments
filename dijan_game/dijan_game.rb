#!/usr/bin/env ruby
###################################################
###
## 	File: dijan_game.rb
## 	Desc: Diane an Janet's board game
#

MULTIPLER 			= 1

require_relative 'event'

Event.new(10, 'Lottery Winner!')  {100}
Event.new(25, 'Robbery!')         { -(player.cash / 2) }
Event.new( 5, 'Bank Hacked')      { -(player.bank / 2) }


BOARD = [
  "000000000000000",
  "080000000000070",
  "000000000000000",
  "000000000006000",
  "000000000000000",
  "000000000000000",
  "000000000000000",
  "050000000000040",
  "000000000000000",
  "000000000000000",
  "000000000000000",
  "000000000000000",
  "000000000000000",
  "000000000000090",
  "000000000000000"
]

CELL_TYPES = [
  "Park", 		    # 0
  "Street", 		  # 1
  "Pink", 		    # 2
  "Yellow", 		  # 3
  "Lottery", 		  # 4
  "Goldenville", 	# 5
  "Plumeville", 	# 6
  "Poor House", 	# 7
  "Jail", 		    # 8
  "Start" 		    # 9
]

$board = BOARD

BLUES = [
  "A blue card"
]

YELLOWS = [
  "A yellow card"
]

PINKS = [
  "A pink card"
]

$blues 		= BLUES
$yellows 	= YELLOWS
$pinks 		= PINKS

class PoorHouse < RuntimeError; end

class Player

  attr_accessor :name
  attr_accessor :bank, :cash
  attr_accessor :paycheck
  attr_accessor :house, :car, :family
  attr_accessor :house_insurance, :car_insurance, :health_insurance
  attr_accessor :college, :church

  attr_accessor :multipler



  def initialize(player_name)
    @multipler          = MULTIPLER
    @name 	            = player_name
    @bank 	            = 100 * @multipler
    @cash 	            = 10 * @multipler
    @paycheck           = 1 * @multipler
    @house_insurance    = false
    @car_insurance 	    = false
    @health_insurance   = false
    @college            = false
    @family             = 1
    @church             = false
  end

  def deposit(amt)
    @bank += amt
    @cash -= amt
    @multipler += 1 if @bank > 1000
  end

  def withdraw(amt)
    @bank -= amt
    @cash += amt
    -amt
  end

  def hacked
    withdraw(@bank)
  end

  def payday(amt=paycheck)
    amt = amt + amt / 10 if college?
    amt = amt - amt / 10 if church?
    @cash += amt
  end

  def bonus(amt)
    payday(paycheck+amt)
  end

  def expense(amt)
    @cash -= amt
    if @cash <= 0
      @bank += @cash
      @cash = 0
      raise PoorHouse if @bank < 0
    end
    -amt
  end

  def win(amt)
    @cash += amt
    deposit(@cash / 2) if @cash > 100
    amt
  end

  def robbed
    expense(@cash / 2)
  end

  def lotto_winner
    win(@bank * 2)
  end

end # class Player

players = [
  Player.new('Diane'),
  Player.new('Janet'),
  Player.new('Mommy'),
  Player.new('Daddy')
]

Event.new( 95, 'Misc. Expense')    { player.expense(amount) }
Event.new(  5, 'Misc. Contest Win'){ player.win(amount) }
Event.new( 10, 'Lottery Winner!')  { player.lotto_winner }
Event.new( 25, 'Robbery!')         { player.robbed  }
Event.new(  5, 'Bank Hacked!')     { player.hacked }



turn = 0

while players.size > 1 do

  puts
  puts "="*55
  puts "Turn #{turn += 1}"

  p_count = players.size

  p_count.times do |p_index|

    player = players[p_index]

    amount = rand(30*player.multipler)

    print "\tPlayer: #{player.name}"
    print "\tCash: $#{player.cash}"
    print "\tBank: $#{player.bank}"
    puts "\tM: #{player.multipler}"

    begin
      events = Event.check{}
      puts events.join("\n") unless events.empty?
    rescue PoorHouse
      puts events.join("\n") unless events.nil? || events.empty?
      puts "Poor House!"
      players[p_index] = nil
    end

  end

  players.compact!

end # while players.size > 1 do

winner = players.first

puts

if winner
  puts "The winner is #{winner.name} with $#{winner.cash + winner.bank}"
else
  puts "There is no winner ..."
end

puts
