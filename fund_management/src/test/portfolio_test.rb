# src/test/portfolio_test.rb):

require 'minitest/autorun'
require 'minitest/pride'
require_relative '../portfolio'

class PortfolioTest < Minitest::Test
  def setup
    @portfolio = Portfolio.new(name: 'Test Portfolio')
  end

  def test_initialization
    assert_equal 'Test Portfolio', @portfolio.name
    assert_equal 1, @portfolio.assets.size
    assert_includes @portfolio.assets, 'Cash'
  end

  def test_buy
    Transaction.stub :log, nil do
      @portfolio.assets['Cash'].buy(quantity: 1000, price: 1)
      @portfolio.buy(asset_name: 'Stock', quantity: 10, price: 50)
    end
    assert_equal 2, @portfolio.assets.size
    assert_equal 10, @portfolio.assets['Stock'].quantity
    assert_equal 50, @portfolio.assets['Stock'].current_price
    assert_equal 500, @portfolio.assets['Cash'].quantity
  end

  def test_buy_insufficient_funds
    assert_raises RuntimeError, 'Insufficient funds' do
      @portfolio.buy(asset_name: 'Stock', quantity: 10, price: 50)
    end
  end

  def test_sell
    Transaction.stub :log, nil do
      @portfolio.assets['Cash'].buy(quantity: 1000, price: 1)
      @portfolio.buy(asset_name: 'Stock', quantity: 10, price: 50)
      proceeds = @portfolio.sell(asset_name: 'Stock', quantity: 5)
    end
    assert_equal 5, @portfolio.assets['Stock'].quantity
    assert_equal 750, @portfolio.assets['Cash'].quantity
    assert_equal 250, proceeds
  end

  def test_sell_asset_not_found
    assert_raises ArgumentError, 'Asset not found' do
      @portfolio.sell(asset_name: 'NonExistent', quantity: 5)
    end
  end

  # Add more tests for save, load, balance, and extract methods
end
