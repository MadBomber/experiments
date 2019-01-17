# ~/temp/praeses_test/src/game/slot.rb

class Slot < Game
  SLOT_COUNT = 3
  TOKENS     = %w[Cherry Orange Plum Bell Melon Bar]
  KEEP_PLAYING_RESPONSES = %w[y yes sure ok go]

  def initialize(*args)
    super
    @player = @players.first
  end

  def cash
    @player.cash
  end

  def play_one_turn
    bet = @player.place_bet

    results = SLOT_COUNT.times.map{ TOKENS.sample }
    
    print "\nSpinning ... "
    spinning
    puts results.join(' - ')
    puts

    event :slot_machine_result, result: results
    
    winnings = bet * multiplier(results)

    if winnings > 0.0
      @player.win winnings
    else
      @player.lose bet
    end
  end

  private # Don't let anyone outside run our magic formula!
    def multiplier(*tokens)
      case tokens.flatten.uniq.length
        when 1 then 3.0
        when 2 then 2.0
        else 0.0
      end
    end
end # class Slot < Game
