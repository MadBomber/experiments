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
require_relative 'smart_message/lib/smart_message'
require 'yaml'
require 'set'
require 'ruby_llm'
require 'securerandom'

require_relative 'common/status_line'
require_relative 'common/logger'
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
        capsule :calculate_similarity, klass: DogeVSM::Operations::SimilarityCalculatorTool
        capsule :generate_recommendations, klass: DogeVSM::Operations::RecommendationGeneratorTool
      end
    end
  end

  # Main program class with status line support
  class Program
    include Common::StatusLine
    include Common::Logger

    def initialize(provider: :openai, model: 'gpt-4o-mini')
      @provider = provider
      @model = model
      @workflow_stages = ['load_departments', 'calculate_similarity', 'generate_recommendations']
      @current_stage = 0
      @stage_start_times = {}
      @stage_durations = []
      @total_start_time = nil
      
      # Initialize logger with debug level for comprehensive logging
      setup_logger(name: 'doge_vsm', level: :debug)
      logger.info("DogeVSM::Program initialized with provider=#{@provider}, model=#{@model}")
      logger.debug("Workflow stages configured: #{@workflow_stages}")
    end

    def format_time(seconds)
      if seconds < 60
        "#{seconds.to_i}s"
      elsif seconds < 3600
        "#{(seconds / 60).to_i}m #{(seconds % 60).to_i}s"
      else
        "#{(seconds / 3600).to_i}h #{((seconds % 3600) / 60).to_i}m"
      end
    end

    def estimate_remaining_time
      return "calculating..." if @stage_durations.empty? || @current_stage == 0

      # Calculate average time per completed stage
      avg_stage_time = @stage_durations.sum / @stage_durations.length
      logger.debug("Time estimation: avg_stage_time=#{avg_stage_time.round(2)}s from #{@stage_durations.length} completed stages")
      
      # Estimate remaining stages (with some weighting - later stages often take longer)
      remaining_stages = @workflow_stages.length - @current_stage
      stage_multipliers = {
        'load_departments' => 1.0,
        'calculate_similarity' => 1.5,
        'generate_recommendations' => 2.0
      }
      
      estimated_remaining = 0
      (@current_stage...@workflow_stages.length).each do |i|
        stage_name = @workflow_stages[i]
        multiplier = stage_multipliers[stage_name] || 1.0
        stage_estimate = avg_stage_time * multiplier
        estimated_remaining += stage_estimate
        logger.debug("Stage #{stage_name}: estimated #{stage_estimate.round(2)}s (multiplier #{multiplier})")
      end

      logger.debug("Total estimated remaining time: #{estimated_remaining.round(2)}s")
      format_time(estimated_remaining)
    end

    def update_status(stage_name, action = "processing")
      current_time = Time.now
      logger.debug("update_status called: stage=#{stage_name}, action=#{action}")
      
      # Track stage transitions
      if stage_name != @current_stage_name
        if @current_stage_name && @stage_start_times[@current_stage_name]
          duration = current_time - @stage_start_times[@current_stage_name]
          @stage_durations << duration
          logger.info("Stage '#{@current_stage_name}' completed in #{duration.round(2)}s")
        end
        
        @current_stage_name = stage_name
        @stage_start_times[stage_name] = current_time
        old_stage = @current_stage
        @current_stage = @workflow_stages.index(stage_name) || @current_stage
        
        if old_stage != @current_stage
          logger.info("Workflow stage transition: #{old_stage} -> #{@current_stage} (#{stage_name})")
        end
      end

      # Calculate progress
      progress = "#{@current_stage + 1}/#{@workflow_stages.length}"
      
      # Format stage name for display
      display_name = case stage_name
                    when 'load_departments' then '📂 Loading departments'
                    when 'calculate_similarity' then '🔍 Analyzing similarity'
                    when 'generate_recommendations' then '💡 Generating recommendations'
                    else "🔄 #{stage_name}"
                    end

      # Create status with time estimation
      eta = estimate_remaining_time
      elapsed = @total_start_time ? format_time(current_time - @total_start_time) : "0s"
      
      status_text = "#{display_name} (#{progress}) | Elapsed: #{elapsed} | ETA: #{eta}"
      logger.debug("Status line update: #{status_text}")
      status_line(status_text)
    end

    def run
      @total_start_time = Time.now
      logger.info("=" * 80)
      logger.info("DOGE VSM Analysis System Starting")
      logger.info("=" * 80)
      logger.info("Provider: #{@provider}, Model: #{@model}")
      logger.info("Start time: #{@total_start_time}")
      logger.info("PID: #{Process.pid}")
      logger.info("Ruby version: #{RUBY_VERSION}")
      logger.info("Environment variables: LLM_PROVIDER=#{ENV['LLM_PROVIDER']}, LLM_MODEL=#{ENV['LLM_MODEL']}")
      
      puts "🇺🇸 Department of Government Efficiency - AI-Powered VSM Analysis System"
      puts "Provider: #{@provider.upcase} | Model: #{@model}"
      puts "=" * 60
      puts "📋 This analysis will:"
      puts "   1. 📂 Load all department YAML configurations" 
      puts "   2. 🔍 Calculate similarity between departments"
      puts "   3. 💡 Generate consolidation recommendations"
      puts "   4. 💰 Estimate cost savings opportunities"
      puts
      puts "⏱️  Expected duration: 1-3 minutes (depends on AI processing time)"
      puts "🛠️  For detailed logs, use: VSM_DEBUG_STREAM=1 #{$0}"
      puts

      logger.info("User interface initialized, starting workflow...")
      update_status("initializing", "starting")
      
      Async do
        logger.info("Entering Async context")
        
        logger.info("Building VSM capsule with provider=#{@provider}, model=#{@model}")
        doge = DogeVSM.build_capsule(provider: @provider, model: @model)
        logger.debug("VSM capsule created: #{doge.inspect}")
        
        logger.info("Starting VSM capsule task")
        doge_task = doge.run
        logger.debug("VSM capsule task started: #{doge_task.inspect}")

        session_id = SecureRandom.uuid
        logger.info("Generated session ID: #{session_id}")
        
        analysis_request = <<~REQUEST
          I need you to analyze all the city department YAML configuration files to identify consolidation opportunities for government efficiency.

          Please follow this workflow:
          1. Load all department configurations from *.yml files
          2. Calculate similarity between departments using multiple metrics
          3. Generate detailed consolidation recommendations with cost savings estimates

          Focus on identifying departments with overlapping capabilities, shared infrastructure needs, or coordination benefits.
        REQUEST
        
        logger.debug("Analysis request prepared: #{analysis_request.length} characters")

        puts "🚀 Starting analysis workflow..."
        puts "📤 Sending request to AI Intelligence system..."
        logger.info("Starting analysis workflow, sending request to AI Intelligence system")
        update_status("ai_processing", "sending request")

        message = VSM::Message.new(
          kind: :user,
          payload: analysis_request,
          meta: { session_id: session_id }
        )
        logger.debug("Created VSM message: kind=#{message.kind}, payload_length=#{message.payload.length}, meta=#{message.meta}")
        
        doge.bus.emit message
        logger.info("Message emitted to VSM bus")

        # Message processing with status updates
        processing = true
        last_activity = Time.now
        message_count = 0

        logger.info("Setting up VSM message bus subscription")
        doge.bus.subscribe do |message|
          message_count += 1
          last_activity = Time.now
          logger.debug("VSM Bus Message ##{message_count}: kind=#{message.kind}, payload_size=#{message.payload.to_s.length}, meta=#{message.meta}")
          
          case message.kind
          when :assistant_delta
            logger.debug("Assistant delta received: #{message.payload.inspect}")
            print message.payload
            $stdout.flush
            
          when :assistant
            logger.info("Assistant message: #{message.payload}")
            puts "\n🤖 AI Analysis: #{message.payload}" unless message.payload.empty?
            
            # Check if this is a final completion message - look for typical completion indicators
            completion_patterns = [
              /next steps?/i,
              /further refinement.*required/i,  
              /analysis.*required/i,
              /consolidation.*complete/i,
              /analysis.*complete/i,
              /let me know.*require/i,
              /if.*additional.*data.*required/i,
              /please let me know/i,
              /transition strategy.*ensure/i
            ]
            
            if completion_patterns.any? { |pattern| message.payload.to_s.match?(pattern) }
              logger.info("Detected completion message in assistant response: #{message.payload.slice(0, 100)}...")
              logger.info("Analysis workflow completed successfully (via assistant message)")
              processing = false
            end
            
          when :tool_call
            tool_calls = message.payload.is_a?(Array) ? message.payload : [message.payload]
            tool_calls.each do |call|
              # Handle both VSM formats: {:name, :arguments} and {:tool, :args}
              tool_name = call[:name] || call["name"] || call[:tool] || call["tool"]
              args = call[:arguments] || call["arguments"] || call[:args] || call["args"]
              
              logger.info("Tool call initiated: #{tool_name} with args: #{args}")
              puts "⚙️  Executing tool: #{tool_name}..."
              update_status(tool_name, "executing")
            end
            
          when :tool_result
            tool_name = message.meta&.dig(:tool)
            logger.info("Tool result received for: #{tool_name}")
            logger.debug("Tool result payload: #{message.payload}")
            case tool_name
            when 'load_departments'
              data = message.payload
              logger.info("load_departments completed: #{data[:count]} departments loaded")
              puts "📊 Loaded #{data[:count]} departments for analysis"
              update_status('load_departments', 'completed')
              
            when 'calculate_similarity'
              data = message.payload
              # Handle both hash and direct array results
              if data.is_a?(Hash)
                count = data[:combinations_found] || data["combinations_found"] || 0
                logger.info("calculate_similarity completed: #{count} combinations found")
                puts "🎯 Found #{count} consolidation opportunities"
              else
                logger.info("calculate_similarity completed with data: #{data.class}")
                puts "🎯 Found consolidation opportunities (data format: #{data.class})"
              end
              update_status('calculate_similarity', 'completed')
              
            when 'generate_recommendations'
              recommendations = message.payload
              logger.info("generate_recommendations completed: #{recommendations.is_a?(Hash) ? recommendations[:total_recommendations] : 'unknown count'} recommendations generated")
              logger.debug("Recommendations payload: #{recommendations}")
              
              puts "\n" + "="*60
              puts "📋 DOGE ANALYSIS COMPLETE"
              puts "="*60
              
              # Handle different payload structures defensively
              if recommendations.is_a?(Hash)
                total_recs = recommendations[:total_recommendations] || recommendations[:recommendations]&.length || 0
                puts "Total Recommendations: #{total_recs}"
                
                # Handle savings information if available
                if recommendations[:summary] && recommendations[:summary][:total_estimated_annual_savings]
                  savings = recommendations[:summary][:total_estimated_annual_savings]
                  logger.info("Total estimated annual savings: $#{savings}")
                  puts "Estimated Annual Savings: $#{savings.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
                end
                
                # Handle consolidation themes if available
                if recommendations[:summary] && recommendations[:summary][:top_consolidation_themes]
                  puts "\n🏛️ Top Consolidation Themes:"
                  recommendations[:summary][:top_consolidation_themes].each do |theme, count|
                    puts "  • #{theme}: #{count} opportunities"
                    logger.debug("Consolidation theme: #{theme} (#{count} opportunities)")
                  end
                end

                # Handle individual recommendations if available
                if recommendations[:recommendations]&.any?
                  puts "\n📄 Top 5 Recommendations:"
                  recommendations[:recommendations].first(5).each_with_index do |rec, i|
                    puts "\n#{i+1}. #{rec[:proposed_name] || 'Unnamed Consolidation'} (#{rec[:similarity_score] || 0}% similarity)"
                    
                    if rec[:departments]
                      dept_names = rec[:departments].map { |d| d[:name] || d.to_s }.join(' + ')
                      puts "   📁 Consolidating: #{dept_names}"
                    end
                    
                    if rec.dig(:implementation, :estimated_savings, :estimated_annual_savings)
                      annual_savings = rec[:implementation][:estimated_savings][:estimated_annual_savings]
                      puts "   💰 Est. Savings: $#{annual_savings.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}/year"
                    end
                    
                    if rec[:benefits]&.any?
                      puts "   📋 Key Benefits: #{rec[:benefits].first(2).join(', ')}"
                    end
                    
                    logger.debug("Recommendation #{i+1}: #{rec[:proposed_name]} - #{rec[:departments]}")
                  end
                else
                  puts "No detailed recommendations structure found in payload."
                  puts "Raw recommendations: #{recommendations.inspect.slice(0, 200)}..."
                end
              else
                puts "Received non-hash recommendations payload: #{recommendations.class}"
                puts "Content: #{recommendations.inspect.slice(0, 200)}..."
              end
              
              update_status('generate_recommendations', 'completed')
              logger.info("Analysis workflow completed successfully")
              processing = false
            end

          when :policy
            logger.warn("Policy alert: #{message.payload}")
            puts "⚠️  Policy Alert: #{message.payload}"
            
          when :audit
            logger.info("Audit event: #{message.payload}")
            puts "📋 Audit: #{message.payload}"
            
          else
            logger.debug("Unhandled message kind: #{message.kind}")
          end
        end

        # Async monitoring with status updates
        logger.info("Starting async monitoring task")
        monitor_task = Async do
          monitor_iterations = 0
          while processing
            monitor_iterations += 1
            Async::Task.current.sleep(2.0)
            
            current_time = Time.now
            elapsed = current_time - @total_start_time
            time_since_activity = current_time - last_activity
            
            logger.debug("Monitor iteration #{monitor_iterations}: elapsed=#{elapsed.round(2)}s, inactive_for=#{time_since_activity.round(2)}s")
            
            # Update status periodically
            if @current_stage_name
              update_status(@current_stage_name, "processing")
            end
            
            # Show timeout warning if no activity for too long
            if time_since_activity > 30
              logger.warn("No activity for #{time_since_activity.round(2)}s, showing timeout warning")
              puts "\n⏰ Still processing... This analysis involves complex AI reasoning and may take a few minutes."
              puts "   💡 Tip: Use VSM_DEBUG_STREAM=1 to see detailed processing logs"
              last_activity = current_time
            end
            
            # Maximum timeout - reduced from 300s to 120s for faster debugging
            if elapsed > 120
              logger.error("Analysis timeout reached after #{elapsed.round(2)}s, stopping")
              puts "\n⚠️  Analysis timeout after 2 minutes. Tools are working but AI may have issues with tool chaining."
              puts "   Check the improved system prompt and try again."
              processing = false
              break
            end
            
            # Additional check: if no activity for a very long time, assume completion
            if time_since_activity > 120
              logger.warn("No activity for #{time_since_activity.round(2)}s, assuming analysis completed")
              puts "\n⚠️  No activity detected for over 2 minutes. Analysis appears to have completed."
              processing = false
              break
            end
          end
          logger.info("Monitor task completed after #{monitor_iterations} iterations")
        end

        logger.info("Waiting for monitor task completion")
        begin
          monitor_task.wait
          total_duration = Time.now - @total_start_time
          logger.info("Analysis completed in #{total_duration.round(2)}s")
        ensure
          logger.debug("Cleaning up terminal and restoring state")
          status_line("✅ Analysis complete!")
          sleep(1) # Brief pause to show completion status
          restore_terminal
          logger.info("Terminal state restored")
        end

        puts "\n✅ AI-Powered Government Efficiency Analysis Complete!"
        puts "🤖 Powered by VSM Architecture + RubyLLM + #{@provider.upcase}"
        logger.info("DOGE VSM Analysis System completed successfully")
        logger.info("Final message count: #{message_count}")
        logger.info("=" * 80)
      end
    end
  end
end

# CLI interface
if __FILE__ == $0
  require 'async'

  # Allow provider override via environment
  provider = ENV['LLM_PROVIDER']&.to_sym || :openai
  model = ENV['LLM_MODEL'] || 'gpt-4o'  # Changed from gpt-4o-mini to gpt-4o for better tool chaining
  
  puts "CLI: Creating DogeVSM::Program with provider=#{provider}, model=#{model}"
  
  begin
    # Create and run the program with status line support
    program = DogeVSM::Program.new(provider: provider, model: model)
    puts "CLI: Program created successfully, starting execution"
    program.run
    puts "CLI: Program execution completed"
  rescue => e
    puts "CLI: Fatal error occurred: #{e.class}: #{e.message}"
    puts "CLI: Backtrace:"
    e.backtrace.each { |line| puts "  #{line}" }
    exit(1)
  end
end