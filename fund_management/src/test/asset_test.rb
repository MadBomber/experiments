# src/test/asset_test.rb

require 'minitest/autorun'
require 'minitest/pride'
require_relative '../asset'

class AssetTest < Minitest::Test
  def setup
    @asset = Asset.new(name: 'Test Asset')
  end

  def test_initialization
    assert_equal 'Test Asset', @asset.name
    assert_equal 0, @asset.quantity
    assert_equal 0.0, @asset.purchase_price
    assert_equal 0.0, @asset.current_price
  end

  def test_current_value
    @asset.instance_variable_set(:@quantity, 10)
    @asset.instance_variable_set(:@current_price, 5.0)
    assert_equal 50.0, @asset.current_value
  end

  def test_buy
    Transaction.stub :log, nil do
      @asset.buy(quantity: 5, price: 10.0)
    end
    assert_equal 5, @asset.quantity
    assert_equal 10.0, @asset.purchase_price
    assert_equal 10.0, @asset.current_price
  end

  def test_sell
    Transaction.stub :log, nil do
      @asset.instance_variable_set(:@quantity, 10)
      @asset.sell(quantity: 3)
    end
    assert_equal 7, @asset.quantity
  end

  def test_update_current_price
    Transaction.stub :log, nil do
      @asset.update_current_price(price: 15.0)
    end
    assert_equal 15.0, @asset.current_price
  end

  def test_to_h
    @asset.instance_variable_set(:@quantity, 5)
    @asset.instance_variable_set(:@purchase_price, 10.0)
    @asset.instance_variable_set(:@current_price, 12.0)
    expected = {
      name:           'Test Asset',
      quantity:       5,
      purchase_price: 10.0,
      current_price:  12.0
    }
    assert_equal expected, @asset.to_h
  end
end
