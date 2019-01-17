
class Shoe
  def initialize(deck_count = 2)
    decks = (1..deck_count).map { Deck.new.shuffle }
    @cards = decks
    .reduce([]) { |product, deck| product + deck.cards }
    .map(&:hide)
  end

  def take(open: true)
    card = @cards.pop
    open ? card.open : card
  end
end
