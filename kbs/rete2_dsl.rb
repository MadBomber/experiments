#!/usr/bin/env ruby

require_relative 'rete2'

module ReteII
  module DSL
    class RuleBuilder
      attr_reader :name, :description, :priority, :conditions, :action_block
      
      def initialize(name)
        @name = name
        @description = nil
        @priority = 0
        @conditions = []
        @action_block = nil
        @current_condition_group = []
        @negated = false
      end
      
      def desc(description)
        @description = description
        self
      end
      
      def priority(level)
        @priority = level
        self
      end
      
      def when(type, pattern = {}, &block)
        if block_given?
          pattern = pattern.merge(evaluate_block(&block))
        end
        @conditions << Condition.new(type, pattern, negated: @negated)
        @negated = false
        self
      end
      
      def given(type, pattern = {}, &block)
        when(type, pattern, &block)
      end
      
      def fact(type, pattern = {}, &block)
        when(type, pattern, &block)
      end
      
      def exists(type, pattern = {}, &block)
        when(type, pattern, &block)
      end
      
      def not
        @negated = true
        self
      end
      
      def absent(type, pattern = {}, &block)
        not.when(type, pattern, &block)
      end
      
      def missing(type, pattern = {}, &block)
        not.when(type, pattern, &block)
      end
      
      def then(&block)
        @action_block = block
        self
      end
      
      def action(&block)
        then(&block)
      end
      
      def build
        Rule.new(@name, 
          conditions: @conditions, 
          action: @action_block,
          priority: @priority)
      end
      
      private
      
      def evaluate_block(&block)
        evaluator = PatternEvaluator.new
        evaluator.instance_eval(&block)
        evaluator.pattern
      end
    end
    
    class PatternEvaluator
      attr_reader :pattern
      
      def initialize
        @pattern = {}
      end
      
      def method_missing(method, *args, &block)
        if args.empty? && !block_given?
          Variable.new(method)
        elsif args.length == 1 && !block_given?
          @pattern[method] = args.first
        elsif block_given?
          @pattern[method] = block
        else
          super
        end
      end
      
      def >(value)
        ->(v) { v > value }
      end
      
      def <(value)
        ->(v) { v < value }
      end
      
      def >=(value)
        ->(v) { v >= value }
      end
      
      def <=(value)
        ->(v) { v <= value }
      end
      
      def ==(value)
        value
      end
      
      def !=(value)
        ->(v) { v != value }
      end
      
      def between(min, max)
        ->(v) { v >= min && v <= max }
      end
      
      def in(collection)
        ->(v) { collection.include?(v) }
      end
      
      def matches(pattern)
        ->(v) { v.match?(pattern) }
      end
      
      def any(*values)
        ->(v) { values.include?(v) }
      end
      
      def all(*conditions)
        ->(v) { conditions.all? { |c| c.is_a?(Proc) ? c.call(v) : c == v } }
      end
    end
    
    class Variable
      attr_reader :name
      
      def initialize(name)
        @name = "?#{name}".to_sym
      end
      
      def to_sym
        @name
      end
    end
    
    class KnowledgeBase
      attr_reader :engine, :rules
      
      def initialize
        @engine = ReteEngine.new
        @rules = {}
        @rule_builders = {}
      end
      
      def rule(name, &block)
        builder = RuleBuilder.new(name)
        builder.instance_eval(&block) if block_given?
        @rule_builders[name] = builder
        rule = builder.build
        @rules[name] = rule
        @engine.add_rule(rule)
        builder
      end
      
      def defrule(name, &block)
        rule(name, &block)
      end
      
      def fact(type, attributes = {})
        @engine.add_fact(type, attributes)
      end
      
      def assert(type, attributes = {})
        fact(type, attributes)
      end
      
      def retract(fact)
        @engine.remove_fact(fact)
      end
      
      def run
        @engine.run
      end
      
      def reset
        @engine.working_memory.facts.clear
      end
      
      def facts
        @engine.working_memory.facts
      end
      
      def print_facts
        puts "Working Memory Contents:"
        puts "-" * 40
        facts.each_with_index do |fact, i|
          puts "#{i + 1}. #{fact}"
        end
        puts "-" * 40
      end
      
      def print_rules
        puts "Knowledge Base Rules:"
        puts "-" * 40
        @rule_builders.each do |name, builder|
          puts "Rule: #{name}"
          puts "  Description: #{builder.description}" if builder.description
          puts "  Priority: #{builder.priority}"
          puts "  Conditions: #{builder.conditions.size}"
          builder.conditions.each_with_index do |cond, i|
            negated = cond.negated ? "NOT " : ""
            puts "    #{i + 1}. #{negated}#{cond.type}(#{cond.pattern})"
          end
          puts ""
        end
        puts "-" * 40
      end
    end
    
    module ConditionHelpers
      def less_than(value)
        ->(v) { v < value }
      end
      
      def greater_than(value)
        ->(v) { v > value }
      end
      
      def equals(value)
        value
      end
      
      def not_equal(value)
        ->(v) { v != value }
      end
      
      def one_of(*values)
        ->(v) { values.include?(v) }
      end
      
      def range(min, max)
        ->(v) { v >= min && v <= max }
      end
      
      def satisfies(&block)
        block
      end
    end
  end
  
  def self.knowledge_base(&block)
    kb = DSL::KnowledgeBase.new
    kb.instance_eval(&block) if block_given?
    kb
  end
end

if __FILE__ == $0
  include ReteII::DSL::ConditionHelpers
  
  kb = ReteII.knowledge_base do
    rule "high_temperature_alert" do
      desc "Alert when temperature exceeds safe limits"
      priority 10
      
      when :sensor, type: "temperature", location: "reactor"
      when :reading do
        value greater_than(100)
        unit "celsius"
      end
      not.when :alarm, type: "temperature", active: true
      
      then do |facts, bindings|
        sensor = facts.find { |f| f.type == :sensor }
        reading = facts.find { |f| f.type == :reading }
        puts "🚨 HIGH TEMPERATURE ALERT!"
        puts "   Location: #{sensor[:location]}"
        puts "   Temperature: #{reading[:value]}°#{reading[:unit]}"
        puts "   Action: Activating cooling system"
      end
    end
    
    rule "low_inventory" do
      desc "Check for items that need reordering"
      priority 5
      
      when :item do
        quantity less_than(10)
        category "essential"
      end
      absent :order, status: "pending"
      
      then do |facts, bindings|
        item = facts.find { |f| f.type == :item }
        puts "📦 LOW INVENTORY WARNING"
        puts "   Item: #{item[:name]}"
        puts "   Quantity: #{item[:quantity]}"
        puts "   Action: Creating purchase order"
      end
    end
    
    rule "customer_vip_upgrade" do
      desc "Upgrade customers to VIP status"
      
      when :customer do
        total_purchases greater_than(10000)
        member_since satisfies { |date| date && date < Time.now - (365 * 24 * 60 * 60) }
      end
      not.when :customer, status: "vip"
      
      then do |facts, bindings|
        customer = facts.find { |f| f.type == :customer }
        puts "⭐ VIP UPGRADE"
        puts "   Customer: #{customer[:name]}"
        puts "   Total Purchases: $#{customer[:total_purchases]}"
        puts "   Action: Upgrading to VIP status"
      end
    end
  end
  
  puts "Expert System with DSL"
  puts "=" * 60
  
  kb.print_rules
  
  puts "\nAdding facts..."
  kb.fact :sensor, type: "temperature", location: "reactor", id: 1
  kb.fact :reading, value: 105, unit: "celsius", sensor_id: 1
  kb.fact :item, name: "Safety Valve", quantity: 5, category: "essential"
  kb.fact :customer, name: "John Doe", total_purchases: 15000, member_since: Time.now - (400 * 24 * 60 * 60)
  
  puts "\nRunning inference engine..."
  puts "-" * 60
  kb.run
  
  puts "\n" + "=" * 60
  puts "Current Facts in Working Memory:"
  kb.print_facts
end