# src/test/general_partner_test.rb):

require 'minitest/autorun'
require 'minitest/pride'
require_relative '../general_partner'

class GeneralPartnerTest < Minitest::Test
  def setup
    @gp = GeneralPartner.new(name: 'GP1', management_fee: 0.02)
  end

  def test_initialization
    assert_equal 'GP1', @gp.name
    assert_equal 0.02, @gp.management_fee
  end

  def test_to_h
    expected = {
      name:           'GP1',
      management_fee: 0.02
    }
    assert_equal expected, @gp.to_h
  end

  # Add more tests for manage_fund and withdraw methods
  # once they are implemented
end
