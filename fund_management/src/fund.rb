# src/fund.rb

require_relative 'transaction'
require_relative 'asset'
require_relative 'limited_partner'
require_relative 'general_partner'

# Fund class represents an investment fund
class Fund
  attr_reader :name, :portfolio, :partners, :transactions

  def initialize(name:)
    @name         = name
    @portfolio    = []
    @partners     = { limited: [], general: [] }
    @transactions = []
  end

  def add_partner(partner)
    case partner
    when LimitedPartner
      @partners[:limited] << partner
    when GeneralPartner
      @partners[:general] << partner
    else
      raise ArgumentError, "Invalid partner type"
    end
    Transaction.log(
      type:    :subscribe,
      fund:    name,
      partner: partner.to_h
    )
  end

  def add_asset(asset)
    @portfolio << asset
    Transaction.log(
      type:  :add_asset,
      fund:  name,
      asset: asset.to_h
    )
  end

  # Method to calculate and distribute waterfall payments
  def distribute_waterfall
    # Implementation of waterfall distribution logic
  end

  # Method to project fund value based on rate of return
  def project_value(rate_of_return:, years:)
    # Implementation of value projection
  end
end
