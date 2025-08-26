#!/usr/bin/env ruby
# doge_vsm.rb - Department of Government Efficiency using VSM paradigm
#
# VSM Architecture Benefits:
#
# 1. Identity System
#
# - Defines DOGE's core purpose: government efficiency optimization
# - Establishes invariants ensuring quality and evidence-based decisions
#
# 2. Intelligence System
#
# - AI-ready for LLM integration with sophisticated system prompts
# - Handles conversation flow and tool orchestration
# - Extensible for advanced reasoning capabilities
#
# 3. Operations System - Three Specialized Tools:
#
# - LoadDepartmentsTool: Handles YAML parsing and data extraction
# - SimilarityCalculatorTool: Performs similarity analysis with multiple metrics
# - RecommendationGeneratorTool: Generates detailed consolidation plans with cost estimates
#
# 4. Governance System
#
# - Validates analysis quality (not too few/many combinations)
# - Enforces minimum value thresholds for recommendations
# - Provides policy feedback on analysis quality
#
# 5. Coordination System
#
# - Manages workflow between analysis stages
# - Handles message scheduling and turn management
#
# Key Improvements Over Original:
#
# 1. Separation of Concerns: Each VSM system has specific responsibilities
# 2. Tool-based Architecture: Individual tools can be tested, reused, and extended
# 3. AI Integration Ready: Intelligence system prepared for LLM-driven analysis
# 4. Policy Enforcement: Governance ensures quality standards
# 5. Async Processing: Built on VSM's async foundation for scalability
# 6. Extensibility: Easy to add new analysis tools or modify workflow
#
# Enhanced Output Features:
#
# - Estimated cost savings calculations
# - Consolidation theme analysis
# - Implementation roadmaps
# - Policy validation alerts
# - Rich summary statistics
#
# The VSM paradigm transforms the monolithic DOGE class into a sophisticated, extensible system that's ready for AI integration
# and provides much richer analysis capabilities!

require_relative 'vsm/lib/vsm'
require_relative 'vsm/lib/vsm/drivers/ruby_llm/async_driver'
require 'yaml'
require 'set'
require 'ruby_llm'

require_relative 'doge_vsm/identity'
require_relative 'doge_vsm/intelligence'
require_relative 'doge_vsm/operations'
require_relative 'doge_vsm/governance'
require_relative 'doge_vsm/coordination'

module DogeVSM
  # Build the DOGE VSM capsule
  def self.build_capsule(provider: :anthropic, model: 'claude-3-haiku-20240307')
    VSM::DSL.define(:doge) do
      identity     klass: DogeVSM::Identity
      governance   klass: DogeVSM::Governance
      coordination klass: DogeVSM::Coordination
      intelligence klass: DogeVSM::Intelligence, args: { provider: provider, model: model }
      operations do
        capsule :load_departments, klass: DogeVSM::Operations::LoadDepartmentsTool
        capsule :calculate_similarity, klass: DogeVSM::Operations::SimilarityCalculatorTool
        capsule :generate_recommendations, klass: DogeVSM::Operations::RecommendationGeneratorTool
      end
    end
  end
end

# CLI interface
if __FILE__ == $0
  require 'async'

  Async do
    # Allow provider override via environment
    provider = ENV['LLM_PROVIDER']&.to_sym || :anthropic
    model = ENV['LLM_MODEL'] || 'claude-3-haiku-20240307'
    
    puts "🇺🇸 Department of Government Efficiency - AI-Powered VSM Analysis System"
    puts "Provider: #{provider.upcase} | Model: #{model}"
    puts "=" * 60

    doge = DogeVSM.build_capsule(provider: provider, model: model)

    # Start the capsule processing
    doge_task = doge.run

    # Start the analysis workflow with AI
    session_id = SecureRandom.uuid

    # Send initial user message to trigger analysis
    analysis_request = <<~REQUEST
      I need you to analyze all the city department YAML configuration files to identify consolidation opportunities for government efficiency.

      Please follow this workflow:
      1. Load all department configurations from *.yml files
      2. Calculate similarity between departments using multiple metrics
      3. Generate detailed consolidation recommendations with cost savings estimates

      Focus on identifying departments with overlapping capabilities, shared infrastructure needs, or coordination benefits.
    REQUEST

    doge.bus.emit VSM::Message.new(
      kind: :user,
      payload: analysis_request,
      meta: { session_id: session_id }
    )

    # Message processing loop
    processing = true
    
    doge.bus.subscribe do |message|
      case message.kind
      when :assistant_delta
        # Stream AI responses in real-time
        print message.payload
        $stdout.flush
        
      when :assistant
        puts "\n" if message.payload && !message.payload.empty?
        puts "🤖 AI Analysis: #{message.payload}" unless message.payload.empty?
        
      when :tool_result
        tool_name = message.meta&.dig(:tool)
        case tool_name
        when 'load_departments'
          data = message.payload
          puts "📊 Loaded #{data[:count]} departments for analysis"
          
        when 'calculate_similarity'
          data = message.payload  
          puts "🎯 Found #{data[:combinations_found]} consolidation opportunities"
          
        when 'generate_recommendations'
          recommendations = message.payload
          
          puts "\n" + "="*60
          puts "📋 DOGE ANALYSIS COMPLETE"
          puts "="*60
          puts "Total Recommendations: #{recommendations[:total_recommendations]}"
          
          savings = recommendations[:summary][:total_estimated_annual_savings]
          puts "Estimated Annual Savings: $#{savings.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
          
          puts "\n🏛️ Top Consolidation Themes:"
          recommendations[:summary][:top_consolidation_themes].each do |theme, count|
            puts "  • #{theme}: #{count} opportunities"
          end

          puts "\n📄 Top 5 Recommendations:"
          recommendations[:recommendations].first(5).each_with_index do |rec, i|
            puts "\n#{i+1}. #{rec[:proposed_name]} (#{rec[:similarity_score]}% similarity)"
            puts "   📁 Consolidating: #{rec[:departments].map { |d| d[:name] }.join(' + ')}"
            puts "   💰 Est. Savings: $#{rec[:implementation][:estimated_savings][:estimated_annual_savings].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}/year"
            puts "   📋 Key Benefits: #{rec[:benefits].first(2).join(', ')}"
          end
          
          processing = false
        end

      when :policy
        puts "⚠️  Policy Alert: #{message.payload}"
        
      when :audit
        puts "📋 Audit: #{message.payload}"
      end
    end

    # Keep processing until complete
    while processing
      sleep 0.1
    end

    puts "\n✅ AI-Powered Government Efficiency Analysis Complete!"
    puts "🤖 Powered by VSM Architecture + RubyLLM + #{provider.upcase}"
  end
end