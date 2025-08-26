#!/usr/bin/env ruby
# simple_discovery_test.rb - Simple test of the department discovery logic

puts "=== Testing Department Discovery Logic ==="

# Test the same logic as in city_council/base.rb
puts "\nDiscovering departments in current directory..."

# Discover Ruby-based departments
ruby_departments = Dir.glob("*_department.rb").map do |file|
  File.basename(file, ".rb")
end

# Discover YAML-configured departments  
yaml_departments = Dir.glob("*_department.yml").map do |file|
  File.basename(file, ".yml")
end

# Combine both types
departments = (ruby_departments + yaml_departments).sort.uniq

puts "\nResults:"
puts "  Ruby-based departments: #{ruby_departments.size}"
ruby_departments.each { |dept| puts "    - #{dept}" }

puts "\n  YAML-configured departments: #{yaml_departments.size}"  
yaml_departments.each { |dept| puts "    - #{dept}" }

puts "\n  Total unique departments: #{departments.size}"
puts "  All departments:"
departments.each { |dept| puts "    - #{dept}" }

puts "\n=== Test Results ==="
if departments.size >= 20
  puts "✅ SUCCESS: Discovered #{departments.size} departments (expected 20+)"
else
  puts "❌ FAILED: Only discovered #{departments.size} departments (expected 20+)"
end