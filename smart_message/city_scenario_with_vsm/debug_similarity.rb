#!/usr/bin/env ruby
# Debug script to check similarity calculator data format

require_relative 'vsm/lib/vsm'
require_relative 'doge_vsm/operations/load_departments_tool'
require_relative 'doge_vsm/operations/similarity_calculator_tool'
require 'yaml'
require 'set'
require 'json'

puts "🔧 Loading departments using LoadDepartmentsTool..."
load_tool = DogeVSM::Operations::LoadDepartmentsTool.new
load_result = load_tool.run({})
puts "✅ Loaded #{load_result[:count]} departments"

puts "\n🔧 Checking first department structure..."
first_dept = load_result[:departments].first
puts "Keys: #{first_dept.keys.inspect}"
puts "Sample department:"
puts JSON.pretty_generate(first_dept.slice(*(first_dept.keys.first(5))))

puts "\n🔧 Testing similarity calculator directly with this data..."
calc_tool = DogeVSM::Operations::SimilarityCalculatorTool.new

# Test with low threshold
result = calc_tool.run({ departments: load_result[:departments], threshold: 0.05 })
puts "✅ Direct call result: Found #{result[:combinations_found]} combinations with threshold 0.05"

# Test with very low threshold
result = calc_tool.run({ departments: load_result[:departments], threshold: 0.01 })
puts "✅ Direct call result: Found #{result[:combinations_found]} combinations with threshold 0.01"

if result[:combinations_found] > 0
  puts "\n🔧 First combination example:"
  first_combo = result[:combinations].first
  puts "Score: #{first_combo[:score].round(4)}"
  puts "Dept1: #{first_combo[:dept1][:name]} (#{first_combo[:dept1][:display_name]})"
  puts "Dept2: #{first_combo[:dept2][:name]} (#{first_combo[:dept2][:display_name]})"
  puts "Reasons: #{first_combo[:reasons].join(', ')}"
end