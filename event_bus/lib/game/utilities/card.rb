
class Card
  SUITS = [ :heart, :spade, :diamond, :club ]

  SUIT_SYMBOLS = {
    heart: '♥',
    spade: '♠',
    diamond: '♦',
    club: '♣'
  }

  NUMERICAL_RANKS = (2..10).to_a
  FACE_RANKS = [ :jack, :queen, :king ]
  RANKS = NUMERICAL_RANKS + FACE_RANKS + [ :ace ]

  attr_reader :suit, :rank

  def initialize(rank, suit, is_hidden = false)
    raise ArgumentError.new('Invalid rank') unless valid_rank?(rank)
    raise ArgumentError.new('Invalid suit') unless valid_suit?(suit)

    @rank = rank
    @suit = suit
    @is_hidden = is_hidden
  end

  def numeric?
    NUMERICAL_RANKS.include?(@rank)
  end

  def face?
    FACE_RANKS.include?(@rank)
  end

  def ace?
    @rank == :ace
  end

  def hidden?
    @is_hidden
  end

  def equal_by_rank?(other)
    self.rank == other.rank ||
      self.face? && other.face? ||
      self.rank == 10 && other.face? ||
      self.face? && other.rank == 10 ||
      self.ace? && other.ace?
  end

  def to_s
    if hidden?
      "[ Hidden ]"
    else
      "[ #{ @rank.to_s.capitalize } of #{ SUIT_SYMBOLS[@suit] } ]"
    end
  end

  def hide
    @is_hidden = true
    self
  end

  def open
    @is_hidden = false
    self
  end

  private

  def valid_suit?(suit)
    SUITS.include?(suit)
  end

  def valid_rank?(rank)
    RANKS.include?(rank)
  end
end
