# src/asset.rb

require_relative 'transaction'

# Asset class represents investments held by the fund
class Asset
  attr_reader :name, :quantity, :purchase_price, :current_price

  def initialize(name:)
    @name           = name
    @quantity       = 0
    @purchase_price = 0.0
    @current_price  = 0.0
  end

  def current_value
    @quantity * @current_price
  end

  def buy(quantity:, price:)
    @quantity       += quantity
    @purchase_price  = price
    @current_price   = price
    Transaction.log(
      type:     :asset,
      action:   :buy,
      quantity:,
      price:    @purchase_price,
      value:    current_value
    )
  end

  def sell(quantity:)
    @quantity -= quantity
    Transaction.log(
      type:     :asset,
      action:   :sell,
      quantity:,
      price:    @current_price,
      value:    current_value
    )
  end

  def update_current_price(price:)
    @current_price = price
    Transaction.log(
      type:     :asset,
      action:   :update_current_price,
      quantity: @quantity,
      price:    @current_price,
      value:    current_value
    )
  end

  def to_h
    {
      name:           @name,
      quantity:       @quantity,
      purchase_price: @purchase_price,
      current_price:  @current_price
    }
  end
end
