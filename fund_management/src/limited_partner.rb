# src/limited_partner.rb

# LimitedPartner class represents an investor in the fund
class LimitedPartner
  attr_reader :name, :investment_amount

  def initialize(name:, investment_amount:)
    @name              = name
    @investment_amount = investment_amount
  end

  def invest(fund:, amount:)
    # Logic for investing in the fund
  end

  def withdraw(fund:, amount:)
    # Logic for withdrawing from the fund
  end

  def to_h
    {
      name:              @name,
      investment_amount: @investment_amount
    }
  end
end
