#!/usr/bin/env ruby

module ReteII
  class Fact
    attr_reader :id, :type, :attributes
    
    def initialize(type, attributes = {})
      @id = object_id
      @type = type
      @attributes = attributes
    end
    
    def [](key)
      @attributes[key]
    end
    
    def matches?(pattern)
      return false if pattern[:type] && pattern[:type] != @type
      
      pattern.each do |key, value|
        next if key == :type
        
        if value.is_a?(Proc)
          return false unless @attributes[key] && value.call(@attributes[key])
        elsif value.is_a?(Symbol) && value.to_s.start_with?('?')
          next
        else
          return false unless @attributes[key] == value
        end
      end
      
      true
    end
    
    def to_s
      "#{@type}(#{@attributes.map { |k, v| "#{k}: #{v}" }.join(', ')})"
    end
  end
  
  class WorkingMemory
    attr_reader :facts
    
    def initialize
      @facts = []
      @observers = []
    end
    
    def add_fact(fact)
      @facts << fact
      notify_observers(:add, fact)
      fact
    end
    
    def remove_fact(fact)
      @facts.delete(fact)
      notify_observers(:remove, fact)
      fact
    end
    
    def add_observer(observer)
      @observers << observer
    end
    
    def notify_observers(action, fact)
      @observers.each { |obs| obs.update(action, fact) }
    end
  end
  
  class Token
    attr_accessor :parent, :fact, :node, :children
    
    def initialize(parent, fact, node)
      @parent = parent
      @fact = fact
      @node = node
      @children = []
    end
    
    def facts
      facts = []
      token = self
      while token
        facts.unshift(token.fact) if token.fact
        token = token.parent
      end
      facts
    end
    
    def to_s
      "Token(#{facts.map(&:to_s).join(', ')})"
    end
  end
  
  class AlphaMemory
    attr_accessor :items, :successors, :pattern
    attr_reader :linked
    
    def initialize(pattern = {})
      @items = []
      @successors = []
      @pattern = pattern
      @linked = true
    end
    
    def unlink!
      @linked = false
      @successors.each { |s| s.left_unlink! if s.respond_to?(:left_unlink!) }
    end
    
    def relink!
      @linked = true
      @successors.each { |s| s.left_relink! if s.respond_to?(:left_relink!) }
    end
    
    def activate(fact)
      return unless @linked
      @items << fact
      @successors.each { |s| s.left_activate(fact) }
    end
    
    def deactivate(fact)
      return unless @linked
      @items.delete(fact)
      @successors.each { |s| s.left_deactivate(fact) if s.respond_to?(:left_deactivate) }
    end
  end
  
  class BetaMemory
    attr_accessor :tokens, :successors
    attr_reader :linked
    
    def initialize
      @tokens = []
      @successors = []
      @linked = true
    end
    
    def unlink!
      @linked = false
      @successors.each { |s| s.left_unlink! if s.respond_to?(:left_unlink!) }
    end
    
    def relink!
      @linked = true
      @successors.each { |s| s.left_relink! if s.respond_to?(:left_relink!) }
    end
    
    def add_token(token)
      @tokens << token
      unlink! if @tokens.empty?
      relink! if @tokens.size == 1
    end
    
    def remove_token(token)
      @tokens.delete(token)
      unlink! if @tokens.empty?
    end
  end
  
  class JoinNode
    attr_accessor :alpha_memory, :beta_memory, :successors, :tests
    attr_reader :left_linked, :right_linked
    
    def initialize(alpha_memory, beta_memory, tests = [])
      @alpha_memory = alpha_memory
      @beta_memory = beta_memory
      @successors = []
      @tests = tests
      @left_linked = true
      @right_linked = true
      
      alpha_memory.successors << self if alpha_memory
      beta_memory.successors << self if beta_memory
    end
    
    def left_unlink!
      @left_linked = false
    end
    
    def left_relink!
      @left_linked = true
      @beta_memory.tokens.each { |token| left_activate(token) } if @beta_memory
    end
    
    def right_unlink!
      @right_linked = false
    end
    
    def right_relink!
      @right_linked = true
      @alpha_memory.items.each { |fact| right_activate(fact) } if @alpha_memory
    end
    
    def left_activate(fact)
      return unless @left_linked && @right_linked
      
      parent_tokens = @beta_memory ? @beta_memory.tokens : [Token.new(nil, nil, nil)]
      
      parent_tokens.each do |token|
        if perform_join_tests(token, fact)
          new_token = Token.new(token, fact, self)
          token.children << new_token if token
          @successors.each { |s| s.activate(new_token) }
        end
      end
    end
    
    def right_activate(fact)
      return unless @left_linked && @right_linked
      
      parent_tokens = @beta_memory ? @beta_memory.tokens : [Token.new(nil, nil, nil)]
      
      parent_tokens.each do |token|
        if perform_join_tests(token, fact)
          new_token = Token.new(token, fact, self)
          token.children << new_token if token
          @successors.each { |s| s.activate(new_token) }
        end
      end
    end
    
    def left_deactivate(token)
      token.children.each do |child|
        @successors.each { |s| s.deactivate(child) if s.respond_to?(:deactivate) }
      end
      token.children.clear
    end
    
    def right_deactivate(fact)
      tokens_to_remove = []
      
      if @beta_memory
        @beta_memory.tokens.each do |token|
          token.children.select { |child| child.fact == fact }.each do |child|
            tokens_to_remove << child
            @successors.each { |s| s.deactivate(child) if s.respond_to?(:deactivate) }
          end
        end
      end
      
      tokens_to_remove.each { |token| token.parent.children.delete(token) if token.parent }
    end
    
    private
    
    def perform_join_tests(token, fact)
      @tests.all? do |test|
        token_value = token.facts[test[:token_field_index]]&.attributes&.[](test[:token_field])
        fact_value = fact.attributes[test[:fact_field]]
        
        if test[:operation] == :eq
          token_value == fact_value
        elsif test[:operation] == :ne
          token_value != fact_value
        else
          true
        end
      end
    end
  end
  
  class NegationNode
    attr_accessor :alpha_memory, :beta_memory, :successors, :tests
    
    def initialize(alpha_memory, beta_memory, tests = [])
      @alpha_memory = alpha_memory
      @beta_memory = beta_memory
      @successors = []
      @tests = tests
      @tokens_with_matches = Hash.new { |h, k| h[k] = [] }
      
      alpha_memory.successors << self if alpha_memory
      beta_memory.successors << self if beta_memory
    end
    
    def left_activate(token)
      matches = @alpha_memory.items.select { |fact| perform_join_tests(token, fact) }
      
      if matches.empty?
        new_token = Token.new(token, nil, self)
        token.children << new_token
        @successors.each { |s| s.activate(new_token) }
      else
        @tokens_with_matches[token] = matches
      end
    end
    
    def right_activate(fact)
      @beta_memory.tokens.each do |token|
        if perform_join_tests(token, fact)
          if @tokens_with_matches[token].empty?
            token.children.each do |child|
              @successors.each { |s| s.deactivate(child) if s.respond_to?(:deactivate) }
            end
            token.children.clear
          end
          @tokens_with_matches[token] << fact
        end
      end
    end
    
    def right_deactivate(fact)
      @beta_memory.tokens.each do |token|
        if @tokens_with_matches[token].include?(fact)
          @tokens_with_matches[token].delete(fact)
          
          if @tokens_with_matches[token].empty?
            new_token = Token.new(token, nil, self)
            token.children << new_token
            @successors.each { |s| s.activate(new_token) }
          end
        end
      end
    end
    
    private
    
    def perform_join_tests(token, fact)
      @tests.all? do |test|
        token_value = token.facts[test[:token_field_index]]&.attributes&.[](test[:token_field])
        fact_value = fact.attributes[test[:fact_field]]
        
        if test[:operation] == :eq
          token_value == fact_value
        elsif test[:operation] == :ne
          token_value != fact_value
        else
          true
        end
      end
    end
  end
  
  class ProductionNode
    attr_accessor :rule, :tokens
    
    def initialize(rule)
      @rule = rule
      @tokens = []
    end
    
    def activate(token)
      @tokens << token
      @rule.fire(token.facts)
    end
    
    def deactivate(token)
      @tokens.delete(token)
    end
  end
  
  class Condition
    attr_reader :type, :pattern, :variable_bindings, :negated
    
    def initialize(type, pattern = {}, negated: false)
      @type = type
      @pattern = pattern
      @negated = negated
      @variable_bindings = extract_variables(pattern)
    end
    
    private
    
    def extract_variables(pattern)
      vars = {}
      pattern.each do |key, value|
        if value.is_a?(Symbol) && value.to_s.start_with?('?')
          vars[value] = key
        end
      end
      vars
    end
  end
  
  class Rule
    attr_reader :name, :conditions, :action, :priority
    
    def initialize(name, conditions: [], action: nil, priority: 0)
      @name = name
      @conditions = conditions
      @action = action
      @priority = priority
      @fired_count = 0
    end
    
    def fire(facts)
      @fired_count += 1
      bindings = extract_bindings(facts)
      @action.call(facts, bindings) if @action
    end
    
    private
    
    def extract_bindings(facts)
      bindings = {}
      @conditions.each_with_index do |condition, index|
        next if condition.negated
        fact = facts[index]
        condition.variable_bindings.each do |var, field|
          bindings[var] = fact.attributes[field] if fact
        end
      end
      bindings
    end
  end
  
  class ReteEngine
    attr_reader :working_memory, :rules, :alpha_memories, :production_nodes
    
    def initialize
      @working_memory = WorkingMemory.new
      @rules = []
      @alpha_memories = {}
      @production_nodes = {}
      @root_beta_memory = BetaMemory.new
      
      @working_memory.add_observer(self)
    end
    
    def add_rule(rule)
      @rules << rule
      build_network_for_rule(rule)
    end
    
    def add_fact(type, attributes = {})
      fact = Fact.new(type, attributes)
      @working_memory.add_fact(fact)
      fact
    end
    
    def remove_fact(fact)
      @working_memory.remove_fact(fact)
    end
    
    def update(action, fact)
      if action == :add
        @alpha_memories.each do |pattern, memory|
          memory.activate(fact) if fact.matches?(pattern)
        end
      elsif action == :remove
        @alpha_memories.each do |pattern, memory|
          memory.deactivate(fact) if fact.matches?(pattern)
        end
      end
    end
    
    def run
      @production_nodes.values.each do |node|
        node.tokens.each do |token|
          node.rule.fire(token.facts)
        end
      end
    end
    
    private
    
    def build_network_for_rule(rule)
      current_beta = @root_beta_memory
      
      rule.conditions.each_with_index do |condition, index|
        pattern = condition.pattern.merge(type: condition.type)
        alpha_memory = get_or_create_alpha_memory(pattern)
        
        if condition.negated
          negation_node = NegationNode.new(alpha_memory, current_beta, [])
          new_beta = BetaMemory.new
          negation_node.successors << new_beta
          current_beta = new_beta
        else
          join_node = JoinNode.new(alpha_memory, current_beta, [])
          new_beta = BetaMemory.new
          join_node.successors << new_beta
          current_beta = new_beta
        end
      end
      
      production_node = ProductionNode.new(rule)
      current_beta.successors << production_node
      @production_nodes[rule.name] = production_node
      
      @working_memory.facts.each do |fact|
        @alpha_memories.each do |pattern, memory|
          memory.activate(fact) if fact.matches?(pattern)
        end
      end
    end
    
    def get_or_create_alpha_memory(pattern)
      @alpha_memories[pattern] ||= AlphaMemory.new(pattern)
    end
  end
end

if __FILE__ == $0
  engine = ReteII::ReteEngine.new
  
  puts "Creating a simple expert system for diagnosing car problems..."
  puts "-" * 60
  
  rule1 = ReteII::Rule.new(
    "dead_battery",
    conditions: [
      ReteII::Condition.new(:symptom, { problem: "won't start" }),
      ReteII::Condition.new(:symptom, { problem: "no lights" })
    ],
    action: lambda do |facts, bindings|
      puts "DIAGNOSIS: Dead battery - The car won't start and has no lights"
      puts "RECOMMENDATION: Jump start the battery or replace it"
    end
  )
  
  rule2 = ReteII::Rule.new(
    "flat_tire",
    conditions: [
      ReteII::Condition.new(:symptom, { problem: "pulling to side" }),
      ReteII::Condition.new(:symptom, { problem: "low tire pressure" })
    ],
    action: lambda do |facts, bindings|
      puts "DIAGNOSIS: Flat or low tire"
      puts "RECOMMENDATION: Check tire pressure and inflate or replace tire"
    end
  )
  
  rule3 = ReteII::Rule.new(
    "overheating",
    conditions: [
      ReteII::Condition.new(:symptom, { problem: "high temperature" }),
      ReteII::Condition.new(:symptom, { problem: "steam from hood" }, negated: false),
      ReteII::Condition.new(:symptom, { problem: "coolant leak" }, negated: true)
    ],
    action: lambda do |facts, bindings|
      puts "DIAGNOSIS: Engine overheating (no coolant leak detected)"
      puts "RECOMMENDATION: Check radiator and cooling system"
    end
  )
  
  engine.add_rule(rule1)
  engine.add_rule(rule2)
  engine.add_rule(rule3)
  
  puts "\nAdding symptoms..."
  engine.add_fact(:symptom, { problem: "won't start", severity: "high" })
  engine.add_fact(:symptom, { problem: "no lights", severity: "high" })
  
  puts "\nRunning inference engine..."
  engine.run
  
  puts "\n" + "-" * 60
  puts "\nAdding more symptoms..."
  engine.add_fact(:symptom, { problem: "high temperature", severity: "critical" })
  engine.add_fact(:symptom, { problem: "steam from hood", severity: "high" })
  
  puts "\nRunning inference engine again..."
  engine.run
end