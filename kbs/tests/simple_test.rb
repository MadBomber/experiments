#!/usr/bin/env ruby

require_relative '../rete2'
require_relative '../blackboard'
require_relative '../csv_trading_system'
require_relative '../portfolio_rebalancing_system'
require_relative '../ai_enhanced_kbs'
require 'minitest/autorun'
require 'tempfile'
require 'csv'

class TestReteIICore < Minitest::Test
  def setup
    @engine = ReteII::ReteEngine.new
  end
  
  def test_simple_rule_firing
    fired = false
    
    rule = ReteII::Rule.new(
      "test_rule",
      conditions: [
        ReteII::Condition.new(:person, { age: 25 })
      ],
      action: lambda { |facts, bindings| fired = true }
    )
    
    @engine.add_rule(rule)
    @engine.add_fact(:person, { age: 25, name: "Alice" })
    @engine.run
    
    assert fired, "Rule should have fired"
  end
  
  def test_pattern_matching_with_proc
    matched_facts = []
    
    rule = ReteII::Rule.new(
      "adults_only",
      conditions: [
        ReteII::Condition.new(:person, { 
          age: ->(age) { age >= 18 }
        })
      ],
      action: lambda { |facts, bindings| matched_facts = facts }
    )
    
    @engine.add_rule(rule)
    @engine.add_fact(:person, { age: 25, name: "Adult" })
    @engine.add_fact(:person, { age: 15, name: "Teen" })
    @engine.run
    
    assert_equal 1, matched_facts.size
    assert_equal 25, matched_facts.first[:age]
  end
  
  def test_negation
    fired_with_negation = false
    
    rule_with_negation = ReteII::Rule.new(
      "no_manager",
      conditions: [
        ReteII::Condition.new(:employee, { department: "IT" }),
        ReteII::Condition.new(:manager, { department: "IT" }, negated: true)
      ],
      action: lambda { |facts, bindings| fired_with_negation = true }
    )
    
    @engine.add_rule(rule_with_negation)
    @engine.add_fact(:employee, { department: "IT", name: "Dave" })
    @engine.run
    
    assert fired_with_negation, "Rule with negation should fire when manager is absent"
  end
end

class TestBlackboardCore < Minitest::Test
  def setup
    @temp_db = Tempfile.new(['test_db', '.db'])
    @engine = ReteII::BlackboardEngine.new(db_path: @temp_db.path)
  end
  
  def teardown
    @engine.blackboard.close
    @temp_db.unlink
  end
  
  def test_persistent_facts
    fact = @engine.add_fact(:sensor, { type: "temperature", value: 25 })
    
    assert_instance_of ReteII::PersistedFact, fact
    assert fact.uuid
    assert_equal :sensor, fact.type
    assert_equal 25, fact[:value]
  end
  
  def test_blackboard_messages
    @engine.post_message("TestSender", "alerts", { message: "Test alert" })
    
    message = @engine.consume_message("alerts", "TestConsumer")
    
    assert message
    assert_equal "TestSender", message[:sender]
    assert_equal "alerts", message[:topic]
    assert_equal "Test alert", message[:content][:message]
  end
end

class TestTradingSystemCore < Minitest::Test
  def setup
    @csv_file = create_test_csv
    @system = CSVTradingSystem.new(@csv_file.path)
  end
  
  def teardown
    @csv_file.unlink
  end
  
  def test_moving_average_calculation
    prices = [10, 12, 14, 16, 18]
    ma = @system.calculate_moving_average(prices, 3)
    
    assert_equal 16, ma  # (14 + 16 + 18) / 3
  end
  
  def test_rsi_calculation
    prices = Array.new(20) { |i| 100 + i }  # Steadily increasing prices
    rsi = @system.calculate_rsi(prices)
    
    assert rsi > 50, "RSI should be above 50 for increasing prices"
    assert rsi <= 100, "RSI should not exceed 100"
  end
  
  private
  
  def create_test_csv
    file = Tempfile.new(['test_data', '.csv'])
    CSV.open(file.path, 'w', headers: true) do |csv|
      csv << ['Date', 'Symbol', 'Open', 'High', 'Low', 'Close', 'Volume']
      
      5.times do |i|
        date = Date.today - (4 - i)
        price = 100 + i
        csv << [date, 'TEST', price, price + 1, price - 1, price, 1_000_000]
      end
    end
    file
  end
end

class TestPortfolioCore < Minitest::Test
  def setup
    @system = PortfolioRebalancingSystem.new
  end
  
  def test_portfolio_value_calculation
    @system.instance_variable_get(:@portfolio)[:positions] = {
      "AAPL" => { symbol: "AAPL", shares: 100, status: "open" }
    }
    @system.instance_variable_get(:@portfolio)[:cash] = 50_000
    @system.instance_variable_get(:@current_prices)["AAPL"] = 200
    
    total_value = @system.calculate_total_portfolio_value
    
    assert_equal 70_000, total_value  # 50k cash + 100 * 200
  end
end

class TestAICore < Minitest::Test
  def setup
    @system = AIEnhancedKBS::AIKnowledgeSystem.new
  end
  
  def test_mock_ai_client
    assert_instance_of AIEnhancedKBS::MockAIClient, @system.instance_variable_get(:@ai_client)
  end
  
  def test_fallback_sentiment_analysis
    sentiment = @system.fallback_sentiment_analysis(
      "Company reports strong growth profit earnings", 
      "Revenue beat expectations"
    )
    
    assert_equal "positive", sentiment[:sentiment]
    assert sentiment[:score] > 0
  end
end

if __FILE__ == $0
  puts "🧪 Running Core RETE II System Tests..."
  puts "=" * 60
  puts "Testing: Core Engine, Blackboard, Trading, Portfolio, AI"
  puts "=" * 60
end