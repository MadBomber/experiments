#!/usr/bin/env ruby

require_relative '../rete2_dsl'
include ReteII::DSL::ConditionHelpers

kb = ReteII.knowledge_base do
  rule "high_temperature_alert" do
    desc "Alert when temperature exceeds safe limits"
    priority 10

    on :sensor, type: "temperature", location: "reactor"
    on :reading do
      value greater_than(100)
      unit "celsius"
    end
    without.on :alarm, type: "temperature", active: true

    perform do |facts, bindings|
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

    on :item do
      quantity less_than(10)
      category "essential"
    end
    absent :order, status: "pending"

    perform do |facts, bindings|
      item = facts.find { |f| f.type == :item }
      puts "📦 LOW INVENTORY WARNING"
      puts "   Item: #{item[:name]}"
      puts "   Quantity: #{item[:quantity]}"
      puts "   Action: Creating purchase order"
    end
  end

  rule "customer_vip_upgrade" do
    desc "Upgrade customers to VIP status"

    on :customer do
      total_purchases greater_than(10000)
      member_since satisfies { |date| date && date < Time.now - (365 * 24 * 60 * 60) }
    end
    without.on :customer, status: "vip"

    perform do |facts, bindings|
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
