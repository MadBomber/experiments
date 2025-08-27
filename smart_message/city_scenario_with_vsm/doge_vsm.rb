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

require 'async'
require 'yaml'
require 'set'
require 'securerandom'
require 'securerandom'

require_relative 'common/status_line'
require_relative 'common/logger'

require_relative 'vsm/lib/vsm'
require_relative 'smart_message/lib/smart_message'


require_relative 'doge_vsm/base'
require_relative 'doge_vsm/identity'
require_relative 'doge_vsm/intelligence'
require_relative 'doge_vsm/operations'
require_relative 'doge_vsm/governance'
require_relative 'doge_vsm/coordination'

module DogeVSM
  # Build the DOGE VSM capsule
  def self.build_capsule(provider: :openai, model: 'gpt-4o-mini')
    VSM::DSL.define(:doge) do
      identity     klass: DogeVSM::Identity
      governance   klass: DogeVSM::Governance
      coordination klass: DogeVSM::Coordination
      intelligence klass: DogeVSM::Intelligence, args: { provider: provider, model: model }
      operations do
        capsule :load_departments, klass: DogeVSM::Operations::LoadDepartmentsTool
        capsule :generate_recommendations, klass: DogeVSM::Operations::RecommendationGeneratorTool
        capsule :create_consolidated_departments, klass: DogeVSM::Operations::CreateConsolidatedDepartmentsTool
        capsule :validate_department_template, klass: DogeVSM::Operations::TemplateValidationTool
        capsule :generate_department_template, klass: DogeVSM::Operations::DepartmentTemplateGeneratorTool
      end
    end
  end
end

# CLI interface
if __FILE__ == $0
  system("rm -f log/doge_vsm.log")

  # Allow provider override via environment
  provider = ENV['DOGE_LLM_PROVIDER']&.to_sym || :openai
  model    = ENV['DOGE_LLM_MODEL'] || 'gpt-4o' # Changed from gpt-4o-mini to gpt-4o for better tool chaining

  puts "CLI: Creating DogeVSM::Program with provider=#{provider}, model=#{model}"

  begin
    program = DogeVSM::Base.new(provider: provider, model: model)
    puts "CLI: Program created successfully, starting execution"
    program.run
    puts "CLI: Program execution completed"
    exit(0)
  rescue => e
    puts "CLI: Fatal error occurred: #{e.class}: #{e.message}"
    puts "CLI: Backtrace:"
    e.backtrace.each { |line| puts "  #{line}" }
    exit(1)
  end
end
