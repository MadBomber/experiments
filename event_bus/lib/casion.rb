# encoding: utf-8
# frozen_string_literal: true
##########################################################
###
##  File: casino.rb
##  Desc: Model of an evil casino
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

# Typical model of an evil casino making money off of weakness of gambling
class Casino
  attr_reader :owner
  attr_reader :company_name

  def initialize(company_name: 'Everyone is a Loser Here Casino', max_odds: 35)
    @company_name = company_name
    @owner        = 'Lucky Larry'
    @max_odds     = max_odds     # The percentage chance that a play has of winning any game    
    event :casino_joined_syndicate, 
            owner: @owner,
            casino_name: @company_name,
            odds_of_any_player_winning: @max_odds
  end
end # class Casino
