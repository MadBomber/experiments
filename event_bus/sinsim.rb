#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
##########################################################
###
##  File: sinsim.rb
##  Desc: Sin Simulation of Gambling at a Casino
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

BANK_RECORDS_FILE_NAME = 'bank.json'

require 'require_all'
require 'event_bus'
require 'tty-spinner'
require 'tty-prompt'

require 'event_bus'

require 'awesome_print'

require 'debug_me'
include DebugMe

require 'cli_helper'
include CliHelper

configatron.version = '0.0.1'

HELP = <<EOHELP
Important:

  You don't need to do this. Go home to your family.

EOHELP

cli_helper("Sin Simulation of Gambling at a Casino") do |o|

  o.int     '-c', '--count',  'How many Players (count)'

end

# Display the usage info
if  ARGV.empty?
  show_usage
  exit
end


# Error check your stuff; use error('some message') and warning('some message')


unless configatron.count
  warning 'This is an exclusive joint; only one player allowed at a time.'
  configatron.count = 1
end


if configatron.count < 0
  error "I don't know about where youz guyz are from; but here thar an't no negative people."
end



abort_if_errors


require_all 'lib'

######################################################
# Local methods

def message(a_string)
  puts a_string
end

def ask(a_string, options={})
  configatron.prompt.ask(a_string, options)
end


def event(event_name, options={})
  EventBus.announce(event_name, options.merge(timestamp: Time.now))
end


  def configure_prompt
    configatron.prompt = TTY::Prompt.new
    configatron.prompt.on(:keypress) do |event|
      case event.value
      when 'j'
        configatron.prompt.trigger(:keydown)
      when 'k'
        configatron.prompt.trigger(:keyup)
      end
    end
  end

  def configure_spinner
    configatron.spinner = TTY::Spinner.new(
      "Simulated Playing ...  :spinner",
      hide_cursor:  true,
      clear:        true,
      format:       :pulse_2
    )
  end


  def spinning(how_long=2)
    configatron.spinner.auto_spin
    sleep(how_long)
    configatron.spinner.stop
  end

def prompt
  configatron.prompt
end

def spinner
  configatron.spinner
end

def select_a_game
  message "\nTo leave Sin City Simulation use Control-C"
  begin
    result = configatron.prompt.select("Choose your game?", configatron.games.keys.sort)
  rescue TTY::Reader::InputInterrupt
    message <<~BYE

      ==============================================================---
      == Hopefully you've learned that gambling is not a good hobby. ==
      =================================================================

    BYE
    exit(0)
  end
  return result
end


######################################################
# Main

at_exit do
  puts
  StatsRecorder.dump
  puts
  puts "Done."
  puts
end

EventBus.subscribe(/.*/,StatsRecorder.new, :an_event)

configure_prompt
configure_spinner


ap configatron.to_h  if verbose? || debug?

configatron.casinos = [Casino.new]
configatron.players = []
configatron.games   = Hash.new

Game.choose_a_game.each{|g| configatron.games[g.to_s] = g}

event(  :sinsim_started, 
        casino_count: configatron.casinos.count, 
        player_count: configatron.count,
        game_count:   configatron.games.count
     )

message <<~WELCOME

  This is the Sin-city Simulation
  by MadBomber

  Currently #{configatron.casinos.size} casino(s) are open for business.
  Your party plan is to start at the first casino and work your way down the strip.

  To get started each member of your party will need to be registered with the
  city's consummer protection agency (CPA) so that we can better help you squander
  your wealth.

  When you are asked a question, I suggest you respond politely by pressing
  the return key after your answer.

WELCOME

# NOTE: Get the names and bankrolls of all players
configatron.count.times do |x|
  player_name = ask("What is the full name of party dog ##{x+1} ?")
  wealth = ask("How much are you willing to loss?").to_f
  configatron.players << Player.new(player_name, wealth)

  event :player_registered,
        player_name:   player_name,
        player_wealth: wealth
  
  message "\nGot it.  #{player_name} is willing to lose #{configatron.players.last.account.balance}"
  if wealth < 0.0
    message "\nAs per city rules, negative numbers represent a request for credit."
    message "Your loan for #{wealth.abs} has been approved with collaterial already obtained."
  end
  if (x+1) < configatron.count
    message "\nNext party dog, please step forward."
  end
end # configatron.count.times do |x|

begin
  game = select_a_game

  event :game_selected, game_name: game

  message "\nOkay #{game} it is ....."

  current_game = configatron.games[game].new(configatron.players)

  current_game.play
end while true

__END__

