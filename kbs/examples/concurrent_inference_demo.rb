#!/usr/bin/env ruby

require_relative '../rete2'
require_relative '../rete2_dsl'
require 'thread'

# =============================================================================
# Pattern 1: Auto-Inference Mode (Reactive)
# Rules fire immediately when facts are added
# =============================================================================

class ReactiveEngine < ReteII::ReteEngine
  attr_accessor :auto_inference

  def initialize(auto_inference: true)
    super()
    @auto_inference = auto_inference
    @inference_mutex = Mutex.new
  end

  def add_fact(type, attributes = {})
    fact = super(type, attributes)

    # Automatically run inference if enabled
    if @auto_inference
      @inference_mutex.synchronize do
        run
      end
    end

    fact
  end
end

# =============================================================================
# Pattern 2: Background Thread Mode
# Inference runs continuously in a background thread
# =============================================================================

class BackgroundInferenceEngine < ReteII::ReteEngine
  def initialize
    super()
    @running = false
    @inference_thread = nil
    @fact_queue = Queue.new
    @mutex = Mutex.new
  end

  def start_background_inference(interval: 0.1)
    return if @running

    @running = true
    @inference_thread = Thread.new do
      while @running
        begin
          # Process any queued facts
          until @fact_queue.empty?
            fact_data = @fact_queue.pop(true) rescue nil
            if fact_data
              @mutex.synchronize do
                super_add_fact(fact_data[:type], fact_data[:attributes])
              end
            end
          end

          # Run inference
          @mutex.synchronize do
            run
          end

          sleep interval
        rescue => e
          puts "Background inference error: #{e.message}"
        end
      end
    end

    puts "✓ Background inference started (interval: #{interval}s)"
  end

  def stop_background_inference
    @running = false
    @inference_thread&.join
    puts "✓ Background inference stopped"
  end

  def add_fact(type, attributes = {})
    @fact_queue.push({type: type, attributes: attributes})
    puts "  → Fact queued: #{type}(#{attributes.map{|k,v| "#{k}: #{v}"}.join(', ')})"
  end

  private

  def super_add_fact(type, attributes)
    fact = ReteII::Fact.new(type, attributes)
    @working_memory.add_fact(fact)
    fact
  end
end

# =============================================================================
# Pattern 3: Event-Driven with Callbacks
# Execute callbacks immediately when rules fire
# =============================================================================

class EventDrivenEngine < ReteII::ReteEngine
  def initialize
    super()
    @rule_callbacks = {}
  end

  def on_rule(rule_name, &callback)
    @rule_callbacks[rule_name] = callback
  end

  def add_fact(type, attributes = {})
    fact = super(type, attributes)

    # Check each production node and fire matching rules
    @production_nodes.each do |rule_name, node|
      node.tokens.each do |token|
        if token.facts.include?(fact) && @rule_callbacks[rule_name]
          Thread.new do
            @rule_callbacks[rule_name].call(token.facts)
          end
        end
      end
    end

    fact
  end
end

# =============================================================================
# DEMO: Pattern 1 - Auto-Inference (Reactive)
# =============================================================================

def demo_reactive_inference
  puts "\n" + "="*80
  puts "PATTERN 1: Auto-Inference Mode (Reactive)"
  puts "="*80
  puts "Facts trigger immediate inference\n\n"

  engine = ReactiveEngine.new(auto_inference: true)

  # Define rules
  rule = ReteII::Rule.new(
    "temperature_alert",
    conditions: [
      ReteII::Condition.new(:sensor, {type: "temperature"}),
      ReteII::Condition.new(:reading, {value: ->(v) { v > 100 }})
    ],
    action: lambda do |facts, bindings|
      reading = facts.find { |f| f.type == :reading }
      sensor = facts.find { |f| f.type == :sensor }
      puts "  🔥 RULE FIRED: Temperature Alert!"
      puts "     Location: #{sensor[:location]}"
      puts "     Temperature: #{reading[:value]}°C exceeds threshold!"
    end
  )

  engine.add_rule(rule)

  puts "Adding sensor..."
  engine.add_fact(:sensor, type: "temperature", location: "reactor")
  puts "  ✓ Sensor added (1/2 conditions met)"

  puts "\nAdding high temperature reading (should fire rule immediately)..."
  engine.add_fact(:reading, value: 105, unit: "celsius")
  puts "  ✓ Reading added (2/2 conditions met)"

  puts "\nAdding another high reading (should fire again)..."
  engine.add_fact(:reading, value: 110, unit: "celsius")

  puts "\nAdding normal temperature reading (should not fire)..."
  engine.add_fact(:reading, value: 75, unit: "celsius")
  puts "  ✓ Reading added but rule not fired (condition not met)"
end

# =============================================================================
# DEMO: Pattern 2 - Background Thread
# =============================================================================

def demo_background_inference
  puts "\n" + "="*80
  puts "PATTERN 2: Background Thread Mode"
  puts "="*80
  puts "Inference runs continuously in background\n\n"

  engine = BackgroundInferenceEngine.new

  # Define rules
  rule = ReteII::Rule.new(
    "stock_momentum",
    conditions: [
      ReteII::Condition.new(:stock, {symbol: "AAPL"}),
      ReteII::Condition.new(:price, {change: ->(v) { v > 5 }})
    ],
    action: lambda do |facts, bindings|
      price = facts.find { |f| f.type == :price }
      stock = facts.find { |f| f.type == :stock }
      puts "  📈 RULE FIRED: Stock Momentum Alert!"
      puts "     Stock: #{stock[:symbol]}"
      puts "     Change: +#{price[:change]}%"
    end
  )

  engine.add_rule(rule)

  # Start background processing
  engine.start_background_inference(interval: 0.5)

  puts "\nStreaming facts (processed by background thread)...\n"

  engine.add_fact(:stock, symbol: "AAPL", sector: "Technology")
  sleep 0.7  # Let background thread process

  engine.add_fact(:price, symbol: "AAPL", change: 6.5, timestamp: Time.now)
  sleep 0.7  # Let background thread process

  engine.add_fact(:price, symbol: "AAPL", change: 2.1, timestamp: Time.now)
  sleep 0.7  # Let background thread process

  engine.stop_background_inference
end

# =============================================================================
# DEMO: Pattern 3 - Event-Driven with Callbacks
# =============================================================================

def demo_event_driven
  puts "\n" + "="*80
  puts "PATTERN 3: Event-Driven with Callbacks"
  puts "="*80
  puts "Rules have individual callback handlers\n\n"

  engine = EventDrivenEngine.new

  # Define rule
  rule = ReteII::Rule.new(
    "order_fulfillment",
    conditions: [
      ReteII::Condition.new(:order, {status: "pending"}),
      ReteII::Condition.new(:inventory, {available: ->(v) { v > 0 }})
    ],
    action: lambda do |facts, bindings|
      order = facts.find { |f| f.type == :order }
      inventory = facts.find { |f| f.type == :inventory }
      puts "  📦 RULE FIRED: Order Fulfillment!"
      puts "     Order ID: #{order[:id]}"
      puts "     Item: #{order[:item]}"
      puts "     Available: #{inventory[:available]}"
    end
  )

  engine.add_rule(rule)

  # Register callback
  engine.on_rule("order_fulfillment") do |facts|
    order = facts.find { |f| f.type == :order }
    puts "     ✓ Async callback executed for order #{order[:id]}"
  end

  puts "Adding facts with event callbacks...\n"

  engine.add_fact(:order, id: "ORD-001", status: "pending", item: "Widget")
  puts "  ✓ Order added (1/2 conditions met)"

  engine.add_fact(:inventory, item: "Widget", available: 50)
  puts "  ✓ Inventory added (2/2 conditions met)"

  # Trigger the event-driven execution
  engine.run

  sleep 0.5 # Let async callbacks complete
end

# =============================================================================
# DEMO: Pattern 4 - Queue-Based Processing
# =============================================================================

def demo_queue_based
  puts "\n" + "="*80
  puts "PATTERN 4: Queue-Based Batch Processing"
  puts "="*80
  puts "Facts accumulate and are processed in batches\n\n"

  engine = ReteII::ReteEngine.new
  fact_queue = Queue.new

  # Define rule
  rule = ReteII::Rule.new(
    "batch_processor",
    conditions: [
      ReteII::Condition.new(:transaction, {})
    ],
    action: lambda do |facts, bindings|
      tx = facts.find { |f| f.type == :transaction }
      puts "  💳 RULE FIRED: Transaction Processed!"
      puts "     ID: #{tx[:id]}"
      puts "     Amount: $#{'%.2f' % tx[:amount]}"
    end
  )

  engine.add_rule(rule)

  # Worker thread processes queue
  worker = Thread.new do
    while true
      batch = []
      5.times { batch << fact_queue.pop(true) rescue nil }
      batch.compact!

      break if batch.empty?

      puts "\n→ Processing batch of #{batch.size} facts..."
      batch.each do |fact_data|
        engine.add_fact(fact_data[:type], fact_data[:attributes])
      end

      puts "→ Running inference on batch..."
      engine.run

      sleep 0.5
    end
  end

  # Producer adds facts to queue
  puts "Queuing transactions...\n"

  fact_queue << {type: :transaction, attributes: {id: "TX-001", amount: 100.00}}
  fact_queue << {type: :transaction, attributes: {id: "TX-002", amount: 250.00}}
  fact_queue << {type: :transaction, attributes: {id: "TX-003", amount: 75.50}}
  fact_queue << {type: :transaction, attributes: {id: "TX-004", amount: 500.00}}
  fact_queue << {type: :transaction, attributes: {id: "TX-005", amount: 125.75}}

  puts "  ✓ 5 transactions queued"

  worker.join(3)
end

# =============================================================================
# Run all demos
# =============================================================================

if __FILE__ == $0
  puts "\n🚀 CONCURRENT INFERENCE PATTERNS FOR RETE II\n"

  demo_reactive_inference
  sleep 1

  demo_background_inference
  sleep 1

  demo_event_driven
  sleep 1

  demo_queue_based

  puts "\n" + "="*80
  puts "All demos completed!"
  puts "="*80
end
