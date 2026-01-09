#!/usr/bin/env ruby
# frozen_string_literal: true

# Example usage of the Context Graph Layer
# Demonstrates introspection, queries, and output transformations

require "date"
require_relative "../lib/context_graph"

# Mock FactDB-like store for demonstration
class MockFactDB
  def initialize
    @entities = {
      1 => { id: 1, canonical_name: "Paula Chen", entity_type: :person, aliases: ["Paula", "P. Chen"] },
      2 => { id: 2, canonical_name: "Microsoft", entity_type: :organization, aliases: ["MSFT"] },
      3 => { id: 3, canonical_name: "Google", entity_type: :organization, aliases: ["Alphabet"] },
      4 => { id: 4, canonical_name: "Bob Smith", entity_type: :person, aliases: ["Bob"] }
    }

    @facts = [
      {
        id: 1,
        fact_text: "Paula Chen works at Microsoft as Principal Engineer",
        valid_at: Date.parse("2024-01-10"),
        invalid_at: nil,
        status: "canonical",
        confidence: 0.95,
        entity_mentions: [
          { entity_id: 1, role: "subject" },
          { entity_id: 2, role: "organization" }
        ]
      },
      {
        id: 2,
        fact_text: "Paula Chen worked at Google",
        valid_at: Date.parse("2020-01-15"),
        invalid_at: Date.parse("2024-01-09"),
        status: "superseded",
        confidence: 0.98,
        entity_mentions: [
          { entity_id: 1, role: "subject" },
          { entity_id: 3, role: "organization" }
        ]
      },
      {
        id: 3,
        fact_text: "Paula Chen reports to Bob Smith",
        valid_at: Date.parse("2024-01-10"),
        invalid_at: nil,
        status: "canonical",
        confidence: 0.90,
        entity_mentions: [
          { entity_id: 1, role: "subject" },
          { entity_id: 4, role: "manager" }
        ]
      },
      {
        id: 4,
        fact_text: "Paula Chen was promoted to Senior Engineer at Google",
        valid_at: Date.parse("2022-06-01"),
        invalid_at: Date.parse("2024-01-09"),
        status: "superseded",
        confidence: 0.92,
        entity_mentions: [
          { entity_id: 1, role: "subject" },
          { entity_id: 3, role: "organization" }
        ]
      }
    ]
  end

  def entity_types
    %i[person organization place product event]
  end

  def relationship_types
    %i[works_at reports_to worked_at has_role]
  end

  def entity_service
    self
  end

  def resolve(name)
    @entities.values.find do |e|
      e[:canonical_name].downcase.include?(name.downcase) ||
        e[:aliases].any? { |a| a.downcase.include?(name.downcase) }
    end
  end

  def find(id)
    @entities[id]
  end

  def query_facts(query, at: nil)
    results = @facts.select do |fact|
      fact[:fact_text].downcase.include?(query.downcase) ||
        fact[:entity_mentions].any? { |m| @entities[m[:entity_id]][:canonical_name].downcase.include?(query.downcase) }
    end

    if at
      results = results.select do |fact|
        fact[:valid_at] <= at && (fact[:invalid_at].nil? || fact[:invalid_at] > at)
      end
    end

    results
  end

  def facts_at(date, query: nil)
    query_facts(query || "", at: date)
  end

  def fact_stats(entity_id)
    entity_facts = @facts.select { |f| f[:entity_mentions].any? { |m| m[:entity_id] == entity_id } }
    {
      canonical: entity_facts.count { |f| f[:status] == "canonical" },
      superseded: entity_facts.count { |f| f[:status] == "superseded" },
      corroborated: entity_facts.count { |f| f[:status] == "corroborated" }
    }
  end

  def relationship_types_for(entity_id)
    entity_facts = @facts.select { |f| f[:entity_mentions].any? { |m| m[:entity_id] == entity_id } }
    types = []
    entity_facts.each do |fact|
      types << :works_at if fact[:fact_text].match?(/works?\s+at/i)
      types << :worked_at if fact[:fact_text].match?(/worked\s+at/i)
      types << :reports_to if fact[:fact_text].match?(/reports?\s+to/i)
      types << :has_role if fact[:fact_text].match?(/promoted|engineer|manager/i)
    end
    types.uniq
  end

  def timespan_for(entity_id)
    entity_facts = @facts.select { |f| f[:entity_mentions].any? { |m| m[:entity_id] == entity_id } }
    return nil if entity_facts.empty?

    start_date = entity_facts.map { |f| f[:valid_at] }.min
    end_date = entity_facts.map { |f| f[:invalid_at] || Date.today }.max
    "#{start_date}..#{end_date}"
  end
end

# Mock HTM-like store for demonstration
class MockHTM
  def initialize
    @memories = [
      {
        id: 1,
        content: "We decided to use PostgreSQL for the new project",
        type: :decision,
        importance: 9.0,
        robot_name: "CodeHelper",
        created_at: Date.parse("2024-10-24")
      },
      {
        id: 2,
        content: "Paula prefers async communication over meetings",
        type: :preference,
        importance: 7.0,
        robot_name: "CodeHelper",
        created_at: Date.parse("2024-09-15")
      },
      {
        id: 3,
        content: "The auth system uses JWT tokens with 24h expiry",
        type: :fact,
        importance: 8.0,
        robot_name: "CodeHelper",
        created_at: Date.parse("2024-10-01")
      }
    ]
  end

  def memory_types
    %i[fact context code preference decision question]
  end

  def recall(topic:, timeframe: nil)
    @memories.select do |m|
      m[:content].downcase.include?(topic.to_s.downcase)
    end
  end

  def memory_stats(entity: nil)
    {
      decisions: @memories.count { |m| m[:type] == :decision },
      preferences: @memories.count { |m| m[:type] == :preference },
      facts: @memories.count { |m| m[:type] == :fact },
      context: @memories.count { |m| m[:type] == :context }
    }
  end
end

# Create the Context Graph Layer
puts "=" * 60
puts "Context Graph Layer - Example Usage"
puts "=" * 60

layer = ContextGraph::Layer.new(
  stores: {
    fact_db: MockFactDB.new,
    htm: MockHTM.new
  }
)

# 1. Introspect the schema
puts "\n## 1. Schema Introspection"
puts "-" * 40
schema = layer.introspect
puts "Stores: #{schema[:stores].join(', ')}"
puts "Capabilities: #{schema[:capabilities].join(', ')}"
puts "Entity Types: #{schema[:entity_types].join(', ')}"
puts "Memory Types: #{schema[:memory_types].join(', ')}"

# 2. Introspect a specific topic
puts "\n## 2. Topic Introspection: 'Paula Chen'"
puts "-" * 40
paula_info = layer.introspect("Paula Chen")
if paula_info
  puts "Entity: #{paula_info[:entity][:canonical_name]} (#{paula_info[:entity][:entity_type]})"
  puts "Fact Coverage: #{paula_info[:coverage][:facts]}"
  puts "Relationships: #{paula_info[:relationships].join(', ')}"
  puts "Suggested Queries: #{paula_info[:suggested_queries].join(', ')}"
end

# 3. Query with different output formats
puts "\n## 3. Query: 'Paula Chen' - Triple Format"
puts "-" * 40
triples = layer.query("Paula Chen", format: :triples)
triples.each do |triple|
  puts "  #{triple.join(' -> ')}"
end

puts "\n## 4. Query: 'Paula Chen' - Cypher Format"
puts "-" * 40
cypher = layer.query("Paula Chen", format: :cypher)
puts cypher

puts "\n## 5. Query: 'Paula Chen' - Prolog Format"
puts "-" * 40
prolog = layer.query("Paula Chen", format: :prolog)
puts prolog

puts "\n## 6. Query: 'Paula Chen' - Text Format"
puts "-" * 40
text = layer.query("Paula Chen", format: :text)
puts text

# 4. Temporal query
puts "\n## 7. Temporal Query: What was true on 2023-06-15?"
puts "-" * 40
historical = layer.at("2023-06-15").query("Paula", format: :text)
puts historical

# 5. Diff between dates
puts "\n## 8. Diff: Paula's status 2023-01-01 vs 2024-06-01"
puts "-" * 40
diff = layer.diff("Paula", from: "2023-01-01", to: "2024-06-01")
puts "Topic: #{diff[:topic]}"
puts "From: #{diff[:from]}"
puts "To: #{diff[:to]}"
puts "Added: #{diff[:added].length} items"
puts "Removed: #{diff[:removed].length} items"
puts "Unchanged: #{diff[:unchanged].length} items"

# 6. Suggest strategies
puts "\n## 9. Strategy Suggestions"
puts "-" * 40
strategies = layer.suggest_strategies("What happened in the auth system last week?")
strategies.each do |s|
  puts "  #{s[:strategy]}: #{s[:description]}"
end

puts "\n" + "=" * 60
puts "Example Complete!"
puts "=" * 60
