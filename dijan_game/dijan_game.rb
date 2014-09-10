#!/usr/bin/env ruby
###################################################
###
## 	File: dijan_game.rb
## 	Desc: Diane an Janet's board game
#

NUMBER_OF_PLAYERS 	= 4
MULTIPLER 			= 1

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


class Player

  attr_accessor :name
  attr_reader   :bank, :cash
  attr_accessor :paycheck
  attr_accessor :house, :car, :family
  attr_accessor :house_insurance, :car_insurance, :health_insurance
  attr_accessor :college, :church


  def initialize(player_name)
    @name 	            = player_name
    @bank 	            = 100 * MULTIPLER
    @cash 	            = 10 * MULTIPLER
    @paycheck           = 1 * MULTIPLER
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
    puts "deposited $#{amt}"
  end

  def withdraw(amt)
    @bank -= amt
    @cash += amt
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
    puts "expense #{amt}"
    @cash = @cash - amt
    if @cash <= 0
      @bank += @cash
      @cash = 0
      raise "You are in the poor house" if @bank < 0
    end
  end

  def win(amt)
    puts "win #{amt}"
    @cash += amt
    deposit(@cash / 2) if @cash > 100
  end

  def robbed
    print "Robbed!"
    expense(@cash / 2)
  end

  def lotto_winner
    print "Jackpot!"
    win(@bank * 2)
  end

end # class Player

players = [
  Player.new('Diane'),
  Player.new('Janet'),
  Player.new('Mommy'),
  Player.new('Daddy')
]

turn = 0

while players.size > 1 do

  puts
  puts "="*55
  puts "Turn #{turn += 1}"

  p_count = players.size

  p_count.times do |p_index|

    player = players[p_index]

    amount = rand(30*MULTIPLER)
    print "\tPlayer: #{player.name}\tCash: $#{player.cash}\tBank: #{player.bank}\t"
    
    begin
      95 > rand(100) ? player.expense(amount) : player.win(amount)
      player.lotto_winner if 10 > rand(100)
      player.robbed       if 25 > rand(100)
    rescue
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
