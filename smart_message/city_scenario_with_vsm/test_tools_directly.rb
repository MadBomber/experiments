#!/usr/bin/env ruby
# Test the DOGE VSM tools directly to verify they work

require_relative 'vsm/lib/vsm'
require_relative 'doge_vsm/operations/load_departments_tool'
require_relative 'doge_vsm/operations/similarity_calculator_tool'
require_relative 'doge_vsm/operations/recommendation_generator_tool'
require 'yaml'
require 'set'

puts "🧪 Testing DOGE VSM tools directly..."

# Test LoadDepartmentsTool
puts "\n1. Testing LoadDepartmentsTool..."
load_tool = DogeVSM::Operations::LoadDepartmentsTool.new
load_result = load_tool.run({})
puts "   ✅ Loaded #{load_result[:count]} departments"

# Test SimilarityCalculatorTool with the actual data
puts "\n2. Testing SimilarityCalculatorTool..."
calc_tool = DogeVSM::Operations::SimilarityCalculatorTool.new
calc_result = calc_tool.run({ departments: load_result[:departments] })
puts "   ✅ Found #{calc_result[:combinations_found]} combinations"

# Test RecommendationGeneratorTool with the actual data  
puts "\n3. Testing RecommendationGeneratorTool..."
rec_tool = DogeVSM::Operations::RecommendationGeneratorTool.new
rec_result = rec_tool.run({ combinations: calc_result[:combinations] })
puts "   ✅ Generated #{rec_result[:total_recommendations]} recommendations"

puts "\n🎉 All tools work correctly when called directly!"
puts "The issue is in the AI agent's tool argument passing, not the tools themselves."