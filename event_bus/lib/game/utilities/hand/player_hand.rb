
class PlayerHand < Hand
  attr_reader :bet

  def initialize(player, bet, cards)
    @player = player
    @bet = bet

    super(cards)
  end

  def split(first_card, second_card)
    raise Errors::HandError.new('Unable to split') unless can_split?

    last_card = @cards.pop
    @cards.push(first_card)
    PlayerHand.new(@player, @bet, [ last_card, second_card ])
  end

  def stand
    raise Errors::HandError.new('Unable to stand') unless can_stand?

    @state = :stand

    self
  end

  def stand?
    @state == :stand
  end

  def append(card)
    raise Errors::HandError.new('Unable to append: hand is marked as stand') if stand?

    super(card)
  end

  def playable?
    !(stand? || busted?) && value < 21
  end

  def can_stand?
    !(stand? || busted?)
  end

  def can_hit?
    can_stand?
  end

  def can_double?
    can_hit? && @player.can_afford?(bet)
  end

  def can_split?
    can_double? &&
      state == :initial &&
      @cards.first.equal_by_rank?(@cards.last)
  end

  def options
    return [] if busted? || stand?

    [].tap do |options|
      options << :hit if can_hit?
      options << :stand if can_stand?
      options << :double if can_double?
      options << :split if can_split?
    end
  end

  def double_bet
    @bet *= 2
  end
end
