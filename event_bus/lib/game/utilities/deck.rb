
class Deck
  attr_reader :cards

  def initialize
    @cards = Card::SUITS.reduce([]) do |product, suit|
      product + Card::RANKS.map do |rank|
        Card.new(rank, suit)
      end
    end
  end

  def shuffle
    @cards.shuffle!
    self
  end
end
