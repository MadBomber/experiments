# src/test/fund_test.rb):

require 'minitest/autorun'
require 'minitest/pride'
require_relative '../fund'

class FundTest < Minitest::Test
  def setup
    @fund = Fund.new(name: 'Test Fund')
  end

  def test_initialization
    assert_equal 'Test Fund', @fund.name
    assert_empty @fund.portfolio
    assert_empty @fund.partners[:limited]
    assert_empty @fund.partners[:general]
    assert_empty @fund.transactions
  end

  def test_add_partner_limited
    Transaction.stub :log, nil do
      limited_partner = LimitedPartner.new(
        name:              'LP1',
        investment_amount: 10000
      )
      @fund.add_partner(limited_partner)
    end
    assert_equal 1, @fund.partners[:limited].size
    assert_instance_of LimitedPartner, @fund.partners[:limited].first
  end

  def test_add_partner_general
    Transaction.stub :log, nil do
      general_partner = GeneralPartner.new(
        name:           'GP1',
        management_fee: 0.02
      )
      @fund.add_partner(general_partner)
    end
    assert_equal 1, @fund.partners[:general].size
    assert_instance_of GeneralPartner, @fund.partners[:general].first
  end

  def test_add_partner_invalid
    assert_raises ArgumentError do
      @fund.add_partner('Invalid Partner')
    end
  end

  def test_add_asset
    Transaction.stub :log, nil do
      asset = Asset.new(name: 'Test Asset')
      @fund.add_asset(asset)
    end
    assert_equal 1, @fund.portfolio.size
    assert_instance_of Asset, @fund.portfolio.first
  end

  # Add more tests for distribute_waterfall and project_value
  # methods once they are implemented
end
