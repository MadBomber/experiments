
class DealerHand < Hand
  def open_last_card
    @cards.last.open
    self
  end
end
