# money_test.rb

require 'minitest/autorun'
require_relative 'money'

class TestMoney < Minitest::Test
  def test_creation
    assert_equal Money(10), 10.to_money
    assert_equal Money(10), Money.new(10)
  end

  def test_arithmetic_with_integers
    money = Money(100) # $100.00

    assert_instance_of Money, money + 50
    assert_equal        Money(150), money + 50    # $150.00

    assert_instance_of Money, money - 30
    assert_equal        Money(70), money - 30     # $70.00

    assert_instance_of Money, money * 2
    assert_equal        Money(200), money * 2     # $200.00

    assert_instance_of Money, money / 4
    assert_equal        Money(25), money / 4      # $25.00
  end

  def test_modulo_with_integers
    money = Money(100) # $100.00

    assert_instance_of Money, money % 30
    assert_equal        Money(10), money % 30     # $10.00
  end

  def test_comparison
    assert_equal    Money(100), Money(100)        # $100.00 == $100.00
    assert_operator Money(100), :>, Money(50)     # $100.00 > $50.00
    assert_operator Money(50), :<, Money(100)     # $50.00 < $100.00
  end

  def test_to_s
    assert_equal "$100.00", Money(100).to_s       # $100.00
    assert_equal "$123.45", Money(123.45).to_s    # $123.45
    assert_equal "($123.45)", Money(-123.45).to_s # ($123.45)
  end

  def test_inspect
    assert_equal "Money(100.0)", Money(100).inspect # $100.00
    assert_equal "Money(123.45)", Money(123.45).inspect
  end
end
