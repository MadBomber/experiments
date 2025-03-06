# src/general_partner.rb

# GeneralPartner class represents a managing partner of the fund
class GeneralPartner
  attr_reader :name, :management_fee

  def initialize(name:, management_fee:)
    @name           = name
    @management_fee = management_fee
  end

  def manage_fund(fund)
    # Logic for managing the fund
  end

  def withdraw(fund:, amount:)
    # Logic for withdrawing from the fund
  end

  def to_h
    {
      name:           @name,
      management_fee: @management_fee
    }
  end
end
