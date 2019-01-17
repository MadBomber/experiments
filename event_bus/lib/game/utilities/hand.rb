
class Hand
  include Comparable

  module Errors
    class HandError < StandardError; end
  end

  attr_reader :cards, :state

  def initialize(cards = [])
    @cards = cards
    @state = :initial
  end

  def value
    open_cards = @cards.reject(&:hidden?)

    aces = open_cards.select(&:ace?)

    value_without_aces = open_cards.reject(&:ace?).reduce(0) do |product, card|
      product + (card.numeric? ? card.rank : 10)
    end

    value_of_aces = aces.reduce(0) do |product, ace|
      product + (value_without_aces + product > 10 ? 1 : 11)
    end

    value_without_aces + value_of_aces
  end

  def <<(card)
    append(card)
  end

  def append(card)
    raise Errors::HandError.new('Unable to append: hand is busted') if busted?

    @cards.push(card)

    @state = :pushed

    self
  end

  def busted?
    value > 21
  end

  def blackjack?
    @cards.count == 2 && value == 21
  end

  def to_s
    "Cards: #{ @cards.map(&:to_s).join(', ') }. Value: #{ value }."
  end

  def <=>(other)
    if self.busted? && other.busted?
      0
    elsif self.busted?
      -1
    elsif other.busted?
      1
    else
      self.value <=> other.value
    end
  end
end # class Hand
