#!/usr/bin/env ruby

require_relative 'rete2'
require 'sqlite3'
require 'json'
require 'time'
require 'securerandom'

module ReteII
  class BlackboardMemory
    attr_reader :db, :db_path, :session_id
    
    def initialize(db_path: ':memory:', auto_commit: true)
      @db_path = db_path
      @auto_commit = auto_commit
      @session_id = SecureRandom.uuid
      @observers = []
      @transaction_depth = 0
      
      setup_database
    end
    
    def setup_database
      @db = SQLite3::Database.new(@db_path)
      @db.results_as_hash = true
      
      create_tables
      create_indexes
      setup_triggers
    end
    
    def create_tables
      @db.execute_batch <<-SQL
        CREATE TABLE IF NOT EXISTS facts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uuid TEXT UNIQUE NOT NULL,
          fact_type TEXT NOT NULL,
          attributes TEXT NOT NULL,
          fact_timestamp TIMESTAMP,
          market_timestamp TIMESTAMP,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          session_id TEXT,
          retracted BOOLEAN DEFAULT 0,
          retracted_at TIMESTAMP,
          data_source TEXT,
          market_session TEXT
        );
        
        CREATE TABLE IF NOT EXISTS fact_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fact_uuid TEXT NOT NULL,
          fact_type TEXT NOT NULL,
          attributes TEXT NOT NULL,
          action TEXT NOT NULL,
          timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          session_id TEXT
        );
        
        CREATE TABLE IF NOT EXISTS rules_fired (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          rule_name TEXT NOT NULL,
          fact_uuids TEXT NOT NULL,
          bindings TEXT,
          fired_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          session_id TEXT
        );
        
        CREATE TABLE IF NOT EXISTS blackboard_messages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sender TEXT NOT NULL,
          topic TEXT NOT NULL,
          content TEXT NOT NULL,
          priority INTEGER DEFAULT 0,
          posted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          consumed BOOLEAN DEFAULT 0,
          consumed_by TEXT,
          consumed_at TIMESTAMP
        );
        
        CREATE TABLE IF NOT EXISTS knowledge_sources (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE NOT NULL,
          description TEXT,
          topics TEXT,
          active BOOLEAN DEFAULT 1,
          registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
      SQL
    end
    
    def create_indexes
      @db.execute_batch <<-SQL
        CREATE INDEX IF NOT EXISTS idx_facts_type ON facts(fact_type);
        CREATE INDEX IF NOT EXISTS idx_facts_session ON facts(session_id);
        CREATE INDEX IF NOT EXISTS idx_facts_retracted ON facts(retracted);
        CREATE INDEX IF NOT EXISTS idx_facts_timestamp ON facts(fact_timestamp);
        CREATE INDEX IF NOT EXISTS idx_facts_market_timestamp ON facts(market_timestamp);
        CREATE INDEX IF NOT EXISTS idx_facts_market_session ON facts(market_session);
        CREATE INDEX IF NOT EXISTS idx_fact_history_uuid ON fact_history(fact_uuid);
        CREATE INDEX IF NOT EXISTS idx_rules_fired_session ON rules_fired(session_id);
        CREATE INDEX IF NOT EXISTS idx_messages_topic ON blackboard_messages(topic);
        CREATE INDEX IF NOT EXISTS idx_messages_consumed ON blackboard_messages(consumed);
      SQL
    end
    
    def setup_triggers
      @db.execute_batch <<-SQL
        CREATE TRIGGER IF NOT EXISTS update_fact_timestamp
        AFTER UPDATE ON facts
        BEGIN
          UPDATE facts SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
        END;
      SQL
    end
    
    def add_fact(type, attributes = {})
      uuid = SecureRandom.uuid
      attributes_json = JSON.generate(attributes)
      
      transaction do
        @db.execute(
          "INSERT INTO facts (uuid, fact_type, attributes, session_id) VALUES (?, ?, ?, ?)",
          [uuid, type.to_s, attributes_json, @session_id]
        )
        
        @db.execute(
          "INSERT INTO fact_history (fact_uuid, fact_type, attributes, action, session_id) VALUES (?, ?, ?, ?, ?)",
          [uuid, type.to_s, attributes_json, 'ADD', @session_id]
        )
      end
      
      fact = PersistedFact.new(uuid, type, attributes, self)
      notify_observers(:add, fact)
      fact
    end
    
    def remove_fact(fact)
      uuid = fact.is_a?(PersistedFact) ? fact.uuid : fact
      
      transaction do
        result = @db.get_first_row(
          "SELECT fact_type, attributes FROM facts WHERE uuid = ? AND retracted = 0",
          [uuid]
        )
        
        if result
          @db.execute(
            "UPDATE facts SET retracted = 1, retracted_at = CURRENT_TIMESTAMP WHERE uuid = ?",
            [uuid]
          )
          
          @db.execute(
            "INSERT INTO fact_history (fact_uuid, fact_type, attributes, action, session_id) VALUES (?, ?, ?, ?, ?)",
            [uuid, result['fact_type'], result['attributes'], 'REMOVE', @session_id]
          )
          
          fact = PersistedFact.new(uuid, result['fact_type'].to_sym, JSON.parse(result['attributes'], symbolize_names: true), self)
          notify_observers(:remove, fact)
        end
      end
    end
    
    def update_fact(fact, new_attributes)
      uuid = fact.is_a?(PersistedFact) ? fact.uuid : fact
      attributes_json = JSON.generate(new_attributes)
      
      transaction do
        @db.execute(
          "UPDATE facts SET attributes = ? WHERE uuid = ? AND retracted = 0",
          [attributes_json, uuid]
        )
        
        result = @db.get_first_row(
          "SELECT fact_type FROM facts WHERE uuid = ?",
          [uuid]
        )
        
        if result
          @db.execute(
            "INSERT INTO fact_history (fact_uuid, fact_type, attributes, action, session_id) VALUES (?, ?, ?, ?, ?)",
            [uuid, result['fact_type'], attributes_json, 'UPDATE', @session_id]
          )
        end
      end
    end
    
    def get_facts(type = nil, pattern = {})
      query = "SELECT * FROM facts WHERE retracted = 0"
      params = []
      
      if type
        query += " AND fact_type = ?"
        params << type.to_s
      end
      
      results = @db.execute(query, params)
      
      results.map do |row|
        attributes = JSON.parse(row['attributes'], symbolize_names: true)
        
        if matches_pattern?(attributes, pattern)
          PersistedFact.new(row['uuid'], row['fact_type'].to_sym, attributes, self)
        end
      end.compact
    end
    
    def query_facts(sql_conditions = nil, params = [])
      query = "SELECT * FROM facts WHERE retracted = 0"
      query += " AND #{sql_conditions}" if sql_conditions
      
      results = @db.execute(query, params)
      
      results.map do |row|
        attributes = JSON.parse(row['attributes'], symbolize_names: true)
        PersistedFact.new(row['uuid'], row['fact_type'].to_sym, attributes, self)
      end
    end
    
    def post_message(sender, topic, content, priority: 0)
      content_json = content.is_a?(String) ? content : JSON.generate(content)
      
      @db.execute(
        "INSERT INTO blackboard_messages (sender, topic, content, priority) VALUES (?, ?, ?, ?)",
        [sender, topic, content_json, priority]
      )
    end
    
    def consume_message(topic, consumer)
      transaction do
        result = @db.get_first_row(
          "SELECT * FROM blackboard_messages WHERE topic = ? AND consumed = 0 ORDER BY priority DESC, posted_at ASC LIMIT 1",
          [topic]
        )
        
        if result
          @db.execute(
            "UPDATE blackboard_messages SET consumed = 1, consumed_by = ?, consumed_at = CURRENT_TIMESTAMP WHERE id = ?",
            [consumer, result['id']]
          )
          
          {
            id: result['id'],
            sender: result['sender'],
            topic: result['topic'],
            content: JSON.parse(result['content'], symbolize_names: true),
            priority: result['priority'],
            posted_at: Time.parse(result['posted_at'])
          }
        end
      end
    end
    
    def peek_messages(topic, limit: 10)
      results = @db.execute(
        "SELECT * FROM blackboard_messages WHERE topic = ? AND consumed = 0 ORDER BY priority DESC, posted_at ASC LIMIT ?",
        [topic, limit]
      )
      
      results.map do |row|
        {
          id: row['id'],
          sender: row['sender'],
          topic: row['topic'],
          content: JSON.parse(row['content'], symbolize_names: true),
          priority: row['priority'],
          posted_at: Time.parse(row['posted_at'])
        }
      end
    end
    
    def register_knowledge_source(name, description: nil, topics: [])
      topics_json = JSON.generate(topics)
      
      @db.execute(
        "INSERT OR REPLACE INTO knowledge_sources (name, description, topics) VALUES (?, ?, ?)",
        [name, description, topics_json]
      )
    end
    
    def log_rule_firing(rule_name, fact_uuids, bindings = {})
      @db.execute(
        "INSERT INTO rules_fired (rule_name, fact_uuids, bindings, session_id) VALUES (?, ?, ?, ?)",
        [rule_name, JSON.generate(fact_uuids), JSON.generate(bindings), @session_id]
      )
    end
    
    def get_history(fact_uuid = nil, limit: 100)
      if fact_uuid
        results = @db.execute(
          "SELECT * FROM fact_history WHERE fact_uuid = ? ORDER BY timestamp DESC LIMIT ?",
          [fact_uuid, limit]
        )
      else
        results = @db.execute(
          "SELECT * FROM fact_history ORDER BY timestamp DESC LIMIT ?",
          [limit]
        )
      end
      
      results.map do |row|
        {
          fact_uuid: row['fact_uuid'],
          fact_type: row['fact_type'].to_sym,
          attributes: JSON.parse(row['attributes'], symbolize_names: true),
          action: row['action'],
          timestamp: Time.parse(row['timestamp']),
          session_id: row['session_id']
        }
      end
    end
    
    def get_rule_firings(rule_name = nil, limit: 100)
      if rule_name
        results = @db.execute(
          "SELECT * FROM rules_fired WHERE rule_name = ? ORDER BY fired_at DESC LIMIT ?",
          [rule_name, limit]
        )
      else
        results = @db.execute(
          "SELECT * FROM rules_fired ORDER BY fired_at DESC LIMIT ?",
          [limit]
        )
      end
      
      results.map do |row|
        {
          rule_name: row['rule_name'],
          fact_uuids: JSON.parse(row['fact_uuids']),
          bindings: row['bindings'] ? JSON.parse(row['bindings'], symbolize_names: true) : {},
          fired_at: Time.parse(row['fired_at']),
          session_id: row['session_id']
        }
      end
    end
    
    def transaction(&block)
      @transaction_depth += 1
      begin
        if @transaction_depth == 1
          @db.transaction(&block)
        else
          yield
        end
      ensure
        @transaction_depth -= 1
      end
    end
    
    def add_observer(observer)
      @observers << observer
    end
    
    def notify_observers(action, fact)
      @observers.each { |obs| obs.update(action, fact) }
    end
    
    def clear_session
      transaction do
        @db.execute("UPDATE facts SET retracted = 1, retracted_at = CURRENT_TIMESTAMP WHERE session_id = ?", [@session_id])
      end
    end
    
    def vacuum
      @db.execute("VACUUM")
    end
    
    def stats
      {
        total_facts: @db.get_first_value("SELECT COUNT(*) FROM facts"),
        active_facts: @db.get_first_value("SELECT COUNT(*) FROM facts WHERE retracted = 0"),
        total_messages: @db.get_first_value("SELECT COUNT(*) FROM blackboard_messages"),
        unconsumed_messages: @db.get_first_value("SELECT COUNT(*) FROM blackboard_messages WHERE consumed = 0"),
        rules_fired: @db.get_first_value("SELECT COUNT(*) FROM rules_fired"),
        knowledge_sources: @db.get_first_value("SELECT COUNT(*) FROM knowledge_sources WHERE active = 1")
      }
    end
    
    def close
      @db.close if @db
    end
    
    private
    
    def matches_pattern?(attributes, pattern)
      pattern.all? do |key, value|
        if value.is_a?(Proc)
          attributes[key] && value.call(attributes[key])
        else
          attributes[key] == value
        end
      end
    end
  end
  
  class PersistedFact
    attr_reader :uuid, :type, :attributes
    
    def initialize(uuid, type, attributes, blackboard = nil)
      @uuid = uuid
      @type = type
      @attributes = attributes
      @blackboard = blackboard
    end
    
    def [](key)
      @attributes[key]
    end
    
    def []=(key, value)
      @attributes[key] = value
      @blackboard.update_fact(self, @attributes) if @blackboard
    end
    
    def update(new_attributes)
      @attributes.merge!(new_attributes)
      @blackboard.update_fact(self, @attributes) if @blackboard
    end
    
    def retract
      @blackboard.remove_fact(self) if @blackboard
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
      "#{@type}(#{@uuid[0..7]}...: #{@attributes.map { |k, v| "#{k}=#{v}" }.join(', ')})"
    end
    
    def to_h
      {
        uuid: @uuid,
        type: @type,
        attributes: @attributes
      }
    end
  end
  
  class BlackboardEngine < ReteEngine
    attr_reader :blackboard
    
    def initialize(db_path: ':memory:')
      super()
      @blackboard = BlackboardMemory.new(db_path: db_path)
      @working_memory = @blackboard
      @blackboard.add_observer(self)
    end
    
    def add_fact(type, attributes = {})
      @blackboard.add_fact(type, attributes)
    end
    
    def remove_fact(fact)
      @blackboard.remove_fact(fact)
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
          fact_uuids = token.facts.map { |f| f.respond_to?(:uuid) ? f.uuid : f.object_id.to_s }
          bindings = extract_bindings_from_token(token, node.rule)
          
          @blackboard.log_rule_firing(node.rule.name, fact_uuids, bindings)
          node.rule.fire(token.facts)
        end
      end
    end
    
    def post_message(sender, topic, content, priority: 0)
      @blackboard.post_message(sender, topic, content, priority: priority)
    end
    
    def consume_message(topic, consumer)
      @blackboard.consume_message(topic, consumer)
    end
    
    def stats
      @blackboard.stats
    end
    
    private
    
    def extract_bindings_from_token(token, rule)
      bindings = {}
      rule.conditions.each_with_index do |condition, index|
        next if condition.negated
        fact = token.facts[index]
        if fact && condition.respond_to?(:variable_bindings)
          condition.variable_bindings.each do |var, field|
            bindings[var] = fact.attributes[field] if fact.respond_to?(:attributes)
          end
        end
      end
      bindings
    end
  end
end

if __FILE__ == $0
  puts "Blackboard Memory System Demonstration"
  puts "=" * 70
  
  engine = ReteII::BlackboardEngine.new(db_path: 'knowledge_base.db')
  
  puts "\nAdding persistent facts..."
  sensor1 = engine.add_fact(:sensor, { location: "room_1", type: "temperature", value: 22 })
  sensor2 = engine.add_fact(:sensor, { location: "room_2", type: "humidity", value: 65 })
  alert = engine.add_fact(:alert, { level: "warning", message: "Check sensors" })
  
  puts "Facts added with UUIDs:"
  puts "  Sensor 1: #{sensor1.uuid}"
  puts "  Sensor 2: #{sensor2.uuid}"
  puts "  Alert: #{alert.uuid}"
  
  puts "\nPosting messages to blackboard..."
  engine.post_message("TemperatureMonitor", "sensor_data", { reading: 25, timestamp: Time.now }, priority: 5)
  engine.post_message("HumidityMonitor", "sensor_data", { reading: 70, timestamp: Time.now }, priority: 3)
  engine.post_message("SystemController", "commands", { action: "calibrate", target: "all_sensors" }, priority: 10)
  
  puts "\nConsuming high-priority message..."
  message = engine.consume_message("commands", "MainController")
  puts "  Received: #{message[:content]}" if message
  
  puts "\nUpdating sensor value..."
  sensor1[:value] = 28
  
  puts "\nDatabase Statistics:"
  stats = engine.stats
  stats.each do |key, value|
    puts "  #{key.to_s.gsub('_', ' ').capitalize}: #{value}"
  end
  
  puts "\nFact History (last 5 entries):"
  history = engine.blackboard.get_history(limit: 5)
  history.each do |entry|
    puts "  [#{entry[:timestamp].strftime('%H:%M:%S')}] #{entry[:action]}: #{entry[:fact_type]}(#{entry[:attributes]})"
  end
  
  puts "\nQuerying facts by type..."
  sensors = engine.blackboard.get_facts(:sensor)
  puts "  Found #{sensors.size} sensor(s)"
  sensors.each { |s| puts "    - #{s}" }
  
  puts "\n" + "=" * 70
  puts "Blackboard persisted to: knowledge_base.db"
end