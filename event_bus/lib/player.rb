# encoding: utf-8
# frozen_string_literal: true
##########################################################
###
##  File: player.rb
##  Desc: A generic player class
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

# Casino like to keep track of people
class Player
  attr_reader   :account
  attr_reader   :full_name
  attr_accessor :current_game
  
  def initialize(full_name, wealth=1000.0)
    @full_name     = full_name
    @account       = Account.new(initial_balance: wealth)
    @casino        = configatron.casinos.first
    @current_game  = nil

    message <<~WELCOME
      
      On behalf of #{@casino.owner} and the #{@casino.company_name}
      we bid welcome to #{@full_name} and your wealth of #{@account.balance}

    WELCOME
    choose_a_game
  end

  def lose(amount)
    message <<~LOSER
      
      Shake it off.
      You lost. What's anouther #{amount} to a high roller like you.
      Have another drink on the house.

    LOSER

    @account.lose(amount)
    event :player_lost, amount: amount, player_name: @full_name
  end
  alias_method :withdraw, :lose

  def win(amount)
    message "** WINNER ** You just won #{amount}"
    @account.win(amount)
    financial_status
    event :player_won, amount: amount, player_name: @full_name
  end
  alias_method :reward, :win

  def bankroll
    @account.balance
  end
  alias_method :cash, :bankroll

  def can_afford?(amount)
    bankroll >= amount
  end

  def place_bet
    amount = ask(  "#{bankroll} available. What is your bet?", 
                   default: Game::MINIMUM_BET_SIZE, convert: :float)
    if amount < 0.0
      message <<~BAD

        Hey, we don't take that kind of funny stuff.
        Making it positive.

      BAD
      amount *= -1.0
    end

    bet = amount

    unless can_afford? bet
      message <<~LOAN

        You can't afford #{bet}; but, cheer up the bank may grant you a loan.

      LOAN
      take_out_a_loan_for(bet + 1000.0)
      financial_status
    end

    event :player_placed_bet, amount: bet, player_name: @full_name
    return bet
  end

  def take_out_a_loan_for(amount)
    event :player_requested_loan, amount: amount.abs, player_name: @full_name
    @account.take_out_a_loan amount.abs
    event :player_loan_approved, 
            amount: amount.abs, 
            player_name:  @full_name,
            loan_balance: @account.loan_bal
  end

  def financial_status
    message <<~STATUS

      #{@full_name} now owes #{@account.loan_bal}
      You have #{@account.balance} with which to play.

    STATUS
  end

  def choose_a_game
    @game = Game.choose_a_game
  end
end # class Player
