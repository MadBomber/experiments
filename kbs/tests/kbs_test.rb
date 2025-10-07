#!/usr/bin/env ruby

require_relative '../kbs'
require_relative '../kbs_dsl'
require_relative '../blackboard'
require_relative '../csv_trading_system'
require_relative '../portfolio_rebalancing_system'
require_relative '../ai_enhanced_kbs'
require 'minitest/autorun'
require 'tempfile'
require 'csv'

class TestKBS < Minitest::Test
  def setup
    @engine = KBS::ReteEngine.new
  end
  
  def test_simple_rule_firing
    fired = false
    
    rule = KBS::Rule.new(
      "test_rule",
      conditions: [
        KBS::Condition.new(:person, { age: 25 })
      ],
      action: lambda { |facts, bindings| fired = true }
    )
    
    @engine.add_rule(rule)
    @engine.add_fact(:person, { age: 25, name: "Alice" })
    @engine.run
    
    assert fired, "Rule should have fired"
  end
  
  def test_multiple_conditions
    result = nil
    
    rule = KBS::Rule.new(
      "parent_child",
      conditions: [
        KBS::Condition.new(:person, { role: "parent" }),
        KBS::Condition.new(:person, { role: "child" })
      ],
      action: lambda { |facts, bindings| result = facts.map(&:to_s).join(", ") }
    )
    
    @engine.add_rule(rule)
    @engine.add_fact(:person, { role: "parent", name: "Bob" })
    @engine.add_fact(:person, { role: "child", name: "Charlie" })
    @engine.run
    
    assert_includes result, "parent"
    assert_includes result, "child"
  end
  
  def test_negation
    fired_with_negation = false
    fired_without_negation = false
    
    rule_with_negation = KBS::Rule.new(
      "no_manager",
      conditions: [
        KBS::Condition.new(:employee, { department: "IT" }),
        KBS::Condition.new(:manager, { department: "IT" }, negated: true)
      ],
      action: lambda { |facts, bindings| fired_with_negation = true }
    )
    
    rule_without_negation = KBS::Rule.new(
      "has_manager",
      conditions: [
        KBS::Condition.new(:employee, { department: "IT" }),
        KBS::Condition.new(:manager, { department: "IT" })
      ],
      action: lambda { |facts, bindings| fired_without_negation = true }
    )
    
    @engine.add_rule(rule_with_negation)
    @engine.add_rule(rule_without_negation)
    
    @engine.add_fact(:employee, { department: "IT", name: "Dave" })
    @engine.run
    
    assert fired_with_negation, "Rule with negation should fire when manager is absent"
    assert !fired_without_negation, "Rule without negation should not fire"
    
    @engine.add_fact(:manager, { department: "IT", name: "Eve" })
    fired_with_negation = false
    @engine.run
    
    assert !fired_with_negation, "Rule with negation should not fire when manager is present"
    assert fired_without_negation, "Rule without negation should fire"
  end
  
  def test_fact_removal
    counter = 0
    
    rule = KBS::Rule.new(
      "count_facts",
      conditions: [
        KBS::Condition.new(:item, { type: "widget" })
      ],
      action: lambda { |facts, bindings| counter += 1 }
    )
    
    @engine.add_rule(rule)
    fact1 = @engine.add_fact(:item, { type: "widget", id: 1 })
    fact2 = @engine.add_fact(:item, { type: "widget", id: 2 })
    
    @engine.run
    assert_equal 2, counter
    
    @engine.remove_fact(fact1)
    counter = 0
    @engine.run
    assert_equal 1, counter
  end
  
  def test_pattern_matching_with_proc
    matched_facts = []
    
    rule = KBS::Rule.new(
      "adults_only",
      conditions: [
        KBS::Condition.new(:person, { 
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
  
  def test_unlinking_optimization
    alpha_memory = @engine.alpha_memories.values.first || KBS::AlphaMemory.new
    beta_memory = KBS::BetaMemory.new
    
    assert alpha_memory.linked, "Alpha memory should start linked"
    alpha_memory.unlink!
    assert !alpha_memory.linked, "Alpha memory should be unlinked"
    alpha_memory.relink!
    assert alpha_memory.linked, "Alpha memory should be relinked"
    
    assert beta_memory.linked, "Beta memory should start linked"
    assert beta_memory.tokens.empty?, "Beta memory should start empty"
  end
  
  def test_complex_join
    result = []
    
    rule = KBS::Rule.new(
      "temperature_alert",
      conditions: [
        KBS::Condition.new(:sensor, { location: "room1" }),
        KBS::Condition.new(:reading, { 
          value: ->(v) { v > 30 }
        })
      ],
      action: lambda { |facts, bindings| result = facts }
    )
    
    @engine.add_rule(rule)
    @engine.add_fact(:sensor, { location: "room1", type: "temperature" })
    @engine.add_fact(:reading, { value: 35, unit: "celsius" })
    @engine.run
    
    assert_equal 2, result.size
  end
end

class TestDSL < Minitest::Test
  def test_dsl_rule_creation
    executed = false
    
    # Test DSL rule creation using eval to handle the special syntax
    dsl_code = <<~DSL
      KBS.knowledge_base do
        rule "test_rule" do
          when :person, age: greater_than(18)
          then { |facts, bindings| @executed = true }
        end
      end
    DSL
    
    @executed = false
    kb = eval(dsl_code)
    kb.fact :person, age: 25
    kb.run
    
    assert @executed, "DSL rule should have fired"
  end
  
  def test_dsl_with_traditional_rules
    # Test that DSL can work alongside traditional rule creation
    executed = false
    
    engine = KBS::ReteEngine.new
    rule = KBS::Rule.new(
      "simple_test",
      conditions: [
        KBS::Condition.new(:person, { age: ->(age) { age > 18 } })
      ],
      action: lambda { |facts, bindings| executed = true }
    )
    
    engine.add_rule(rule)
    engine.add_fact(:person, { age: 25 })
    engine.run
    
    assert executed, "Traditional rule should work"
  end
  
  def test_pattern_evaluator_helpers
    # Test the pattern evaluator helper methods directly
    evaluator = KBS::PatternEvaluator.new
    
    # Test greater_than
    gt_func = evaluator.greater_than(10)
    assert gt_func.call(15), "greater_than should work"
    assert !gt_func.call(5), "greater_than should reject smaller values"
    
    # Test between
    between_func = evaluator.between(10, 20)
    assert between_func.call(15), "between should work for middle values"
    assert !between_func.call(25), "between should reject values outside range"
  end
end

class TestBlackboard < Minitest::Test
  def setup
    @temp_db = Tempfile.new(['test_db', '.db'])
    @engine = KBS::BlackboardEngine.new(db_path: @temp_db.path)
  end
  
  def teardown
    @engine.blackboard.close
    @temp_db.unlink
  end
  
  def test_persistent_facts
    fact = @engine.add_fact(:sensor, { type: "temperature", value: 25 })
    
    assert_instance_of KBS::PersistedFact, fact
    assert fact.uuid
    assert_equal :sensor, fact.type
    assert_equal 25, fact[:value]
  end
  
  def test_fact_history
    fact = @engine.add_fact(:sensor, { value: 25 })
    fact[:value] = 30
    
    history = @engine.blackboard.get_history(fact.uuid)
    
    assert history.size >= 2
    assert_includes history.map { |h| h[:action] }, 'ADD'
    assert_includes history.map { |h| h[:action] }, 'UPDATE'
  end
  
  def test_blackboard_messages
    @engine.post_message("TestSender", "alerts", { message: "Test alert" })
    
    message = @engine.consume_message("alerts", "TestConsumer")
    
    assert message
    assert_equal "TestSender", message[:sender]
    assert_equal "alerts", message[:topic]
    assert_equal "Test alert", message[:content][:message]
  end
  
  def test_query_interface
    @engine.add_fact(:sensor, { location: "room1", type: "temperature" })
    @engine.add_fact(:sensor, { location: "room2", type: "humidity" })
    
    sensors = @engine.blackboard.get_facts(:sensor)
    assert_equal 2, sensors.size
    
    temp_sensors = @engine.blackboard.query_facts("json_extract(attributes, '$.type') = ?", ["temperature"])
    assert_equal 1, temp_sensors.size
  end
end

class TestTradingSystem < Minitest::Test
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
  
  def test_breakout_detection
    prices = Array.new(20, 100)  # Flat prices
    current_price = 102  # 2% above resistance
    volume = 2_000_000
    avg_volume = 1_000_000
    
    result = @system.detect_breakout("TEST", current_price, prices, volume, avg_volume)
    
    assert result[:resistance_break], "Should detect price breakout"
    assert result[:volume_confirmation], "Should confirm with volume"
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

class TestPortfolioRebalancing < Minitest::Test
  def setup
    @system = PortfolioRebalancingSystem.new
  end
  
  def test_sector_allocation_calculation
    @system.instance_variable_get(:@portfolio)[:positions] = {
      "AAPL" => { symbol: "AAPL", shares: 100, status: "open" },
      "GOOGL" => { symbol: "GOOGL", shares: 50, status: "open" }
    }
    
    @system.instance_variable_get(:@current_prices).merge!({
      "AAPL" => 200,
      "GOOGL" => 150
    })
    
    allocations = @system.calculate_sector_allocations
    
    assert allocations["Technology"] > 0
    assert_in_delta 1.0, allocations.values.sum, 0.01  # Should sum to ~1.0
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

class TestAIEnhancement < Minitest::Test
  def setup
    @system = AIEnhancedKBS::AIKnowledgeSystem.new
  end
  
  def test_mock_ai_client
    assert_instance_of AIEnhancedKBS::MockAIClient, @system.instance_variable_get(:@ai_client)
  end
  
  def test_sentiment_analysis
    sentiment = @system.analyze_sentiment_with_ai(
      "Company reports strong earnings", 
      "Revenue up 20% year over year"
    )
    
    assert sentiment[:sentiment]
    assert sentiment[:score]
    assert sentiment[:confidence]
  end
  
  def test_fallback_sentiment_analysis
    sentiment = @system.fallback_sentiment_analysis(
      "Company reports strong growth profit earnings", 
      "Revenue beat expectations"
    )
    
    assert_equal "positive", sentiment[:sentiment]
    assert sentiment[:score] > 0
  end
  
  def test_risk_analysis
    position = { symbol: "TEST", unrealized_pnl: -6000 }
    
    risk = @system.fallback_risk_analysis(position)
    
    assert_equal "HIGH", risk[:risk_level]
    assert_includes risk[:risks], "Large unrealized loss"
  end
end

if __FILE__ == $0
  puts "🧪 Running Comprehensive RETE II System Tests..."
  puts "=" * 60
  puts "Testing: Core Engine, DSL, Blackboard, Trading, Portfolio, AI"
  puts "=" * 60
end