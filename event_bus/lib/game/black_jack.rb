# encoding: utf-8
# frozen_string_literal: true
##########################################################
###
##  File: black_jack.rb
##  Desc: a silly win-lose game
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

class BlackJack < Game
  def initialize(*args)
    super

    @player = @players.first
    @shoe   = Shoe.new

    @game_number = 0
  end


  def player
    @player
  end


  # TODO: refactor, isolate the decision points
  def play_one_turn
    @game_number += 1

    event :blackjack_game_starting,
            player_name: player.full_name,
            game_number: @game_number

    message("\n#{self.class} Game ##{ @game_number }") 

    bet = player.place_bet

    @player_hands = [ PlayerHand.new(player, bet, [ @shoe.take, @shoe.take ]) ]
    @dealer_hand  = DealerHand.new([ @shoe.take, @shoe.take(open: false) ])

    @state = :initial

    show_hands(@dealer_hand, @player_hands.first)

    check_on_blackjack

    until over?
      # TODO: refactor this entire "@player_hands" concept
      @player_hands.each_with_index do |hand, hand_index|
        next if hand.options.empty?

        hand_number = hand_index + 1

        hand_count_part = @player_hands.count > 1 ? " (hand №#{ hand_number })" : ''
        
        choice = prompt.select("What to do next#{ hand_count_part }?", 
                               hand.options)

        act(choice, hand_index)

        break if choice == :split
      end # @player_hands.each_with_index do |hand, hand_index|

      show_player_hands
    end # until over?

    dealer_take_your_cards

    @player_hands.each_with_index do |hand, hand_index|
      hand_number = hand_index + 1

      message("Hand №#{ hand_number }") if @player_hands.count > 1
      message('Blackjack!')   if hand.blackjack?

      @player.win(hand.bet)  if hand > @dealer_hand || hand.blackjack?
      @player.lose(hand.bet) if hand < @dealer_hand

      message('Push!')   if hand == @dealer_hand  &&  !hand.blackjack?
    end

    @player.financial_status
  end # def play_one_turn


  def over?
    @state == :over
  end

  def act(action, hand_index)
    raise Errors::UnableToAction.new('Game is over') if over?
    raise Errors::UnableToAction.new('Invalid action') unless valid_action?(action)

    hand = @player_hands[hand_index]

    raise Errors::UnableToAction.new('Unknown hand') if hand.nil?

    self.send(action, hand)

    if ready_to_finish?
      @state = :over

      unless all_hands_busted?
        @dealer_hand.open_last_card

        fill_dealer_hand_until_17

        @player_hands.each do |hand|
          if hand > @dealer_hand
            @player.reward(hand.bet * 2)
          elsif hand == @dealer_hand
            @player.reward(hand.bet)
          end
        end
      end
    end
  end



  ################################################
  private

  def dealer_take_your_cards
    unless @player_hands.count == 1 && @player_hands.first.blackjack?
      message <<~DEALER
      
        Dealer opens his hand and takes cards until 17
        #{@dealer_hand}

      DEALER
    end
  end

  def show_hands(dealer, loser)
    message <<~HANDS

      Dealer's hand:
        #{dealer}

      Your hand:
        #{loser}

    HANDS
  end


  def show_player_hands
    @player_hands.each_with_index do |hand, hand_index|
      hand_number = hand_index + 1
      a_string  = "Your Hand"
      a_string += "(#{hand_number})" if @player_hands.count > 1
      message <<~HAND
      
        #{a_string}:
        #{hand}
      
      HAND
    end
  end

  def all_hands_busted?
    @player_hands
    .map(&:busted?)
    .reduce { |product, is_busted| product && is_busted }
  end


  def fill_dealer_hand_until_17
    until @dealer_hand.value >= 17
      @dealer_hand << @shoe.take
    end
    event :bj_dealer_hand, hand: @dealer_hand.to_s
  end


  def ready_to_finish?
    !@player_hands
      .map(&:playable?)
      .reduce { |product, is_playable| product || is_playable }
  end


  def stand(hand)
    fail unless hand.can_stand?

    hand.stand
    event :bj_player_action, player: player.full_name, action: 'stand', hand: hand.to_s
  end


  def hit(hand)
    fail unless hand.can_hit?

    hand.append(@shoe.take)

    event :bj_player_action, player: player.full_name, action: 'hit', hand: hand.to_s
  end


  def double(hand)
    fail unless hand.can_double?
    event :bj_player_action, player: player.full_name, action: 'double', hand: hand.to_s

    # @player.withdraw(hand.bet) # ... we give players credit when they don't have enought
    hand.double_bet
    hand.append(@shoe.take)
    hand.stand unless hand.busted?
  end


  def split(hand)
    fail unless hand.can_split?
    event :bj_player_action, player: player.full_name, action: 'split', hand: hand.to_s

    @player_hands << hand.split(@shoe.take, @shoe.take)
    # @player.withdraw(hand.bet) # player gets credit if they don't have enought
  end


  def check_on_blackjack
    first_hand = @player_hands.first

    if first_hand.blackjack?
      @state = :over
      amount = first_hand.bet * 1.5
      event :blackjack, player_name: player.full_name, amount: 
      @player.reward(amount)
    end
  end


  def valid_action?(action)
    [ :hit, :stand, :double, :split ].include?(action)
  end
end # class BlackJack < Game

