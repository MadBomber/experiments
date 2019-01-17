# encoding: utf-8
# frozen_string_literal: true
##########################################################
###
##  File: account.rb
##  Desc: A simple bank account to keep track of points
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

# positive balance means the player still has points to lose; a negative balance means the player has taken out a loan
class Account
  attr_reader :balance
  attr_reader :loan_bal
  
  def initialize(initial_balance: 1000.0, interest_rate: 0.5)
    @bank_name = 'You Cannot Get Ahead Bank'
    @owner     = 'Lucky Larry'
    @interest_rate = interest_rate
    @balance   = initial_balance.abs
    @loan_bal  = (initial_balance < 0.0) ? @balance : 0.0
  end

  def win(amount)
    @balance  += amount
    message "Winner! #{amount} has been added to your account. Balance: #{@balance}"
    event :winnings_deposited, amount: amount, balance: @balance, loan_balance: @loan_bal
    loan_reminder
  end

  def lose(amount)
    @balance -= amount
    event :wager_debited, amount: amount, balance: @balance, loan_balance: @loan_bal
    take_out_a_loan if @balance <= 0.0
  end

  def take_out_a_loan(amount=1000)
    @loan_bal += amount
    @balance  += amount
    message "#{@owner} tankz youz for youz business. Youz owe #{@loan_bal}"
    if @loan_bal > 1500.0
      message "#{@owner} thinks you might need to start thinking about collateral."
    end
    event :loan_approved_by_bank, amount: amount, balance: @balance, loan_balance: @loan_bal
  end

  def loan_reminder
    interest = @loan_bal * @interest_rate
    if interest > 0.0
      @loan_bal += interest
      event :interest_on_loan_charged, amount: interest, rate: @interest_rate*100.0, loan_balance: @loan_bal
    end

    if @loan_bal > 0.0 and @balance > @loan_bal
      message "You should consider paying off your loan balance of #{@loan_bal}"
    end
    if @loan_bal > 2000.0
      message "#{@owner} is very interested in getting his points back!  You owe: #{@loan_bal}"
    end
    if @loan_bal > 2500.0
      @interest_rate += 0.1
      event :interest_rate_hike, 
            increased_by: 10.0, 
            rate: @interest_rate*100.0,
            loan_balance: @loan_bal
      message "#{@owner} says your interest rate has gone up to #{@interest_rate*100.0}%."
    end
  end
end # class Account
