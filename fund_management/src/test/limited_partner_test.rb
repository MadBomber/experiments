# src/test/limited_partner_test.rb):

require 'minitest/autorun'
require 'minitest/pride'
require_relative '../limited_partner'

class LimitedPartnerTest < Minitest::Test
  def setup
    @lp = LimitedPartner.new(name: 'LP1', investment_amount: 10000)
  end

  def test_initialization
    assert_equal 'LP1', @lp.name
    assert_equal 10000, @lp.investment_amount
  end

  def test_to_h
    expected = {
      name:              'LP1',
      investment_amount: 10000
    }
    assert_equal expected, @lp.to_h
  end

  # Add more tests for invest and withdraw methods
  # once they are implemented
end
