# src/test/transaction_test.rb):

require 'minitest/autorun'
require 'minitest/pride'
require_relative '../transaction'

class TransactionTest < Minitest::Test
  def setup
    @test_file = 'test_transactions.json'
    Transaction.const_set(:FILE_PATH, @test_file)
  end

  def teardown
    File.delete(@test_file) if File.exist?(@test_file)
  end

  def test_log
    transaction_data = {
      type:   :test,
      action: :buy,
      amount: 100
    }

    Transaction.log(transaction_data)

    transactions = JSON.parse(File.read(@test_file), symbolize_names: true)
    assert_equal 1, transactions.size
    assert_equal :test, transactions.first[:type]
    assert_equal :buy, transactions.first[:action]
    assert_equal 100, transactions.first[:amount]
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/,
                 transactions.first[:timestamp])
  end

  def test_log_invalid_input
    assert_raises ArgumentError, 'Expected a hash as input' do
      Transaction.log('invalid input')
    end
  end

  def test_log_multiple_transactions
    3.times do |i|
      Transaction.log(type: :test, id: i)
    end

    transactions = JSON.parse(File.read(@test_file), symbolize_names: true)
    assert_equal 3, transactions.size
    assert_equal [0, 1, 2], transactions.map { |t| t[:id] }
  end
end
