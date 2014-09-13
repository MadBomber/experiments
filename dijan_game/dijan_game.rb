#!/usr/bin/env ruby
###################################################
###
## 	File: dijan_game.rb
## 	Desc: Diane an Janet's board game
#

MULTIPLER 			= 1

require_relative 'event'

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
    @paycheck           = 123 * @multipler
    @house_insurance    = false
    @car_insurance 	    = false
    @health_insurance   = false
    @college            = false
    @family             = 1
    @church             = false
  end

  def college?
    @college
  end

  def church?
    @church
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
    b = @bank
    @bank = 0
    -b
  end

  def payday(amt=nil)
    amt = @paycheck if amt.nil?
    amt = amt + amt / 10 if college?
    amt = amt - amt / 10 if church?
    @cash += amt
    deposit(@cash / 2)
    amt
  end

  def bonus(amt)
    unless 0 == @paycheck
      payday(paycheck+amt)
    else
      0
    end
  end

  def expense(amt)
    @cash -= amt
    if @cash <= 0
      @bank += @cash
      @cash = 0
    end
    -amt
  end

  def win(amt)
    @cash += amt
    deposit(@cash / 2) if @cash > 100
    amt
  end

  def robbed
    if @cash > 0
      expense(@cash / 2)
    else
      0
    end
  end

  def lotto_winner
    win(@bank * 2)
  end

  def poor_house?
    @bank < 0
  end

  def amount
    rand(30*@multipler) + @multipler
  end

end # class Player





players = [
  Player.new('Diane'),
  Player.new('Janet'),
  Player.new('Mommy'),
  Player.new('Daddy')
]

Event.new(  5, 'Misc. Contest Win') { player.win(player.amount) }
Event.new( 10, 'Lottery Winner!')   { player.lotto_winner }
Event.new(  7, 'Payday!')           { player.payday }
Event.new(  2, 'Bonus!')            { player.bonus(player.amount*100) }

Event.new( 25, 'Misc. Expense')    { player.expense(player.amount) }

Event.new( 25, 'Robbery!')         { player.robbed  }
Event.new(  5, 'Bank Hacked!')     { player.hacked }

Event.new(  5, 'Health Expense')      { player.expense(player.amount) }
Event.new(  5, 'Car insurance ex[ense')    { player.expense(player.amount) }
Event.new(  5, 'House Expense')       { player.expense(player.amount) }
Event.new(  5, 'Doctor Expense')      { player.expense(player.amount) }
Event.new(  5, 'Grocery Expense')     { player.expense(player.amount) }
Event.new(  5, 'Eat Out Expense')     { player.expense(player.amount) }
Event.new(  5, 'Movie Expense')       { player.expense(player.amount) }
Event.new(  5, 'Entertainment Expense') { player.expense(player.amount) }
Event.new(  5, 'Gas Expense')         { player.expense(player.amount) }
Event.new(  5, 'Elecity Expense')     { player.expense(player.amount) }
Event.new(  5, 'Utilities Expense')   { player.expense(player.amount) }
Event.new(  5, 'Lottery Ticket')      { player.expense(player.amount) }
Event.new( 15, 'Feed the pet, woofie'){ player.expense(player.amount) }
Event.new( 15, 'Feed the kids')       { player.expense(player.amount) }

Event.new(  5, 'Lose you job')        { player.paycheck = 0 }
Event.new(  5, 'Get a raise')         { player.paycheck = player.paycheck + player.amount; 0 }
Event.new(  2, 'Pass a College class'){ player.college = true; 0 }
Event.new(  2, 'Join a Church')       { player.church = true; 0 }


turn = 0

while players.size > 1 do

  puts
  puts "="*55
  puts "Turn #{turn += 1}"

  p_count = players.size

  p_count.times do |p_index|

    player = players[p_index]

    print "\tPlayer: #{player.name}"
    print "\tCash: $#{player.cash}"
    print "\tBank: $#{player.bank}"
    puts "\tM: #{player.multipler}"

    events = Event.check
    puts events.join("\n") unless events.empty?

    print "\t   Results -=>"
    print "\tCash: $#{player.cash}"
    print "\tBank: $#{player.bank}"
    puts "\tM: #{player.multipler}"


    if player.poor_house?
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
