# doge_vsm/base.rb
# Base class for DOGE VSM program implementations

module DogeVSM
  class Base
    include Common::StatusLine
    include Common::Logger

    def initialize(provider: :openai, model: 'gpt-4o-mini')
      @provider = provider
      @model = model
      @workflow_stages = ['load_departments', 'generate_recommendations', 'create_consolidated_departments']
      @current_stage = 0
      @stage_start_times = {}
      @stage_durations = []
      @total_start_time = nil

      setup_logger(name: 'doge_vsm', level: :debug)
      logger.info("DogeVSM::Base initialized with provider=#{@provider}, model=#{@model}")
      logger.debug("Workflow stages configured: #{@workflow_stages}")
    end

    def run
      log_startup_info
      print_startup_banner

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

        analysis_request = create_analysis_request
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

        # Message processing with status updates using array references for mutability
        processing = [true]
        last_activity = [Time.now]
        message_count = [0]

        logger.info("Setting up VSM message bus subscription")
        setup_message_handler(doge, processing, last_activity, message_count)
        setup_completion_detection(processing, last_activity)

        puts "\n✅ AI-Powered Government Efficiency Analysis Complete!"
        puts "🤖 Powered by VSM Architecture + RubyLLM + #{@provider.upcase}"
        logger.info("DOGE VSM Analysis System completed successfully")
        logger.info("Final message count: #{message_count[0]}")
        logger.info("=" * 80)
        exit(0)
      end
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

      avg_stage_time = @stage_durations.sum / @stage_durations.length
      logger.debug("Time estimation: avg_stage_time=#{avg_stage_time.round(2)}s from #{@stage_durations.length} completed stages")

      remaining_stages = @workflow_stages.length - @current_stage
      stage_multipliers = {
        'load_departments' => 1.0,
        'generate_recommendations' => 2.5
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

      progress = "#{@current_stage + 1}/#{@workflow_stages.length}"

      display_name = case stage_name
                    when 'load_departments' then '📂 Loading departments'
                    when 'generate_recommendations' then '💡 Generating recommendations'
                    when 'create_consolidated_departments' then '🏗️ Creating consolidated departments'
                    else "🔄 #{stage_name}"
                    end

      eta = estimate_remaining_time
      elapsed = @total_start_time ? format_time(current_time - @total_start_time) : "0s"

      status_text = "#{display_name} (#{progress}) | Elapsed: #{elapsed} | ETA: #{eta}"
      logger.debug("Status line update: #{status_text}")
      status_line(status_text)
    end

    def print_startup_banner
      puts "🇺🇸 Department of Government Efficiency - AI-Powered VSM Analysis System"
      puts "Provider: #{@provider.upcase} | Model: #{@model}"
      puts "=" * 60
      puts "📋 This analysis will:"
      puts "   1. 📂 Load all department YAML configurations"
      puts "   2. 🧠 AI analyzes similarities and overlapping functions"
      puts "   3. 💡 Generate consolidation recommendations"
      puts "   4. 💰 Estimate cost savings opportunities"
      puts
      puts "⏱️  Expected duration: 1-3 minutes (depends on AI processing time)"
      puts "🛠️  For detailed logs, use: VSM_DEBUG_STREAM=1 #{$0}"
      puts
    end

    def log_startup_info
      @total_start_time = Time.now
      logger.info("=" * 80)
      logger.info("DOGE VSM Analysis System Starting")
      logger.info("=" * 80)
      logger.info("Provider: #{@provider}, Model: #{@model}")
      logger.info("Start time: #{@total_start_time}")
      logger.info("PID: #{Process.pid}")
      logger.info("Ruby version: #{RUBY_VERSION}")
      logger.info("Environment variables: LLM_PROVIDER=#{ENV['LLM_PROVIDER']}, LLM_MODEL=#{ENV['LLM_MODEL']}")
    end

    def create_analysis_request
      <<~REQUEST
        I need you to analyze all the city department YAML configuration files to identify consolidation opportunities for government efficiency.

        Please follow this workflow:
        1. Load all department configurations from *.yml files
        2. Analyze the departments directly to identify overlapping functions, shared capabilities, and similar responsibilities
        3. Generate detailed consolidation recommendations with cost savings estimates

        Focus on identifying departments with overlapping capabilities, shared infrastructure needs, or coordination benefits. Look for common keywords, similar functions, and opportunities to combine related services.
      REQUEST
    end

    def handle_assistant_delta(message)
      logger.debug("Assistant delta received: #{message.payload.inspect}")
      print message.payload
      $stdout.flush
    end

    def handle_assistant_message(message, processing)
      logger.info("Assistant message: #{message.payload}")
      puts "\n🤖 AI Analysis: #{message.payload}" unless message.payload.empty?

      completion_patterns = [
        /recommendations.*when implemented.*planning/i,
        /operational efficiencies/i,
        /maintain service quality/i,
        /consolidation.*can.*improve/i,
        /these recommendations/i,
        /analysis.*complete/i,
        /efficiency.*improvements/i,
        /resource.*optimization/i,
        /detailed planning.*community engagement.*critical/i,
        /no degradation.*service quality.*citizens/i
      ]

      if completion_patterns.any? { |pattern| message.payload.to_s.match?(pattern) }
        logger.info("Detected completion message in assistant response: #{message.payload.slice(0, 100)}...")
        logger.info("Analysis workflow completed successfully (via assistant message)")
        processing[0] = false
      end
    end

    def handle_tool_call(message)
      tool_calls = message.payload.is_a?(Array) ? message.payload : [message.payload]
      tool_calls.each do |call|
        tool_name = call[:name] || call["name"] || call[:tool] || call["tool"]
        args = call[:arguments] || call["arguments"] || call[:args] || call["args"]

        logger.info("Tool call initiated: #{tool_name} with args: #{args}")
        puts "⚙️  Executing tool: #{tool_name}..."
        update_status(tool_name, "executing")
      end
    end

    def handle_load_departments_result(data)
      logger.info("load_departments completed: #{data[:count]} departments loaded")
      puts "📊 Loaded #{data[:count]} departments for analysis"
      update_status('load_departments', 'completed')
    end

    def handle_recommendations_result(recommendations, processing)
      logger.info("generate_recommendations completed: #{recommendations.is_a?(Hash) ? recommendations[:total_recommendations] : 'unknown count'} recommendations generated")
      logger.debug("Recommendations payload: #{recommendations}")

      puts "\n" + "="*60
      puts "📋 DOGE ANALYSIS COMPLETE"
      puts "="*60

      if recommendations.is_a?(Hash)
        display_recommendations_summary(recommendations)
        display_top_recommendations(recommendations)
      else
        puts "Received non-hash recommendations payload: #{recommendations.class}"
        puts "Content: #{recommendations.inspect.slice(0, 200)}..."
      end

      update_status('generate_recommendations', 'completed')
    end

    def handle_consolidation_result(consolidation_result, processing)
      logger.info("create_consolidated_departments completed")
      logger.debug("Consolidation result payload: #{consolidation_result}")

      puts "\n" + "="*60
      puts "🎉 CONSOLIDATED DEPARTMENTS CREATED!"
      puts "="*60

      if consolidation_result.is_a?(Hash)
        if consolidation_result[:successful_consolidations]
          puts "✅ Successfully created #{consolidation_result[:successful_consolidations]} consolidated departments"
        end
        
        if consolidation_result[:total_consolidations]
          puts "📊 Total consolidations processed: #{consolidation_result[:total_consolidations]}"
        end

        if consolidation_result[:consolidations]
          puts "\n📁 New Department Files Created:"
          consolidation_result[:consolidations].each do |consolidation|
            if consolidation[:success]
              puts "  ✅ #{consolidation[:yaml_file]} (merged #{consolidation[:merged_departments]&.length || 0} departments)"
              if consolidation[:doged_files]&.any?
                puts "     📦 Archived: #{consolidation[:doged_files].map { |f| f[:original] }.join(', ')}"
              end
            else
              puts "  ❌ Failed: #{consolidation[:new_department_name]} - #{consolidation[:error]}"
            end
          end
        end

        if consolidation_result[:errors]&.any?
          puts "\n⚠️  Errors encountered:"
          consolidation_result[:errors].each { |error| puts "  • #{error}" }
        end

        if consolidation_result[:summary]
          summary = consolidation_result[:summary]
          puts "\n📈 Consolidation Summary:"
          puts "  • New department files: #{summary[:new_department_files]&.length || 0}"
          puts "  • Total departments merged: #{summary[:total_departments_merged] || 0}"
          puts "  • Total capabilities: #{summary[:total_capabilities] || 0}"
        end
      else
        puts "Received non-hash consolidation result: #{consolidation_result.class}"
        puts "Content: #{consolidation_result.inspect.slice(0, 200)}..."
      end

      update_status('create_consolidated_departments', 'completed')
      logger.info("Complete DOGE workflow finished successfully")
      processing[0] = false
    end

    def display_recommendations_summary(recommendations)
      total_recs = recommendations[:total_recommendations] || recommendations[:recommendations]&.length || 0
      puts "Total Recommendations: #{total_recs}"

      if recommendations[:summary] && recommendations[:summary][:total_estimated_annual_savings]
        savings = recommendations[:summary][:total_estimated_annual_savings]
        logger.info("Total estimated annual savings: $#{savings}")
        puts "Estimated Annual Savings: $#{savings.to_s.reverse.gsub(/(\\d{3})(?=\\d)/, '\\\\1,').reverse}"
      end

      if recommendations[:summary] && recommendations[:summary][:top_consolidation_themes]
        puts "\n🏛️ Top Consolidation Themes:"
        recommendations[:summary][:top_consolidation_themes].each do |theme, count|
          puts "  • #{theme}: #{count} opportunities"
          logger.debug("Consolidation theme: #{theme} (#{count} opportunities)")
        end
      end
    end

    def display_top_recommendations(recommendations)
      return unless recommendations[:recommendations]&.any?

      puts "\n📄 Top 5 Recommendations:"
      recommendations[:recommendations].first(5).each_with_index do |rec, i|
        puts "\n#{i+1}. #{rec[:proposed_name] || 'Unnamed Consolidation'} (#{rec[:similarity_score] || 0}% similarity)"

        if rec[:departments]
          dept_names = rec[:departments].map { |d| d[:name] || d.to_s }.join(' + ')
          puts "   📁 Consolidating: #{dept_names}"
        end

        if rec.dig(:implementation, :estimated_savings, :estimated_annual_savings)
          annual_savings = rec[:implementation][:estimated_savings][:estimated_annual_savings]
          puts "   💰 Est. Savings: $#{annual_savings.to_s.reverse.gsub(/(\\d{3})(?=\\d)/, '\\\\1,').reverse}/year"
        end

        if rec[:benefits]&.any?
          puts "   📋 Key Benefits: #{rec[:benefits].first(2).join(', ')}"
        end

        logger.debug("Recommendation #{i+1}: #{rec[:proposed_name]} - #{rec[:departments]}")
      end
    end

    def handle_tool_result(message, processing)
      tool_name = message.meta&.dig(:tool)
      logger.info("Tool result received for: #{tool_name}")
      logger.debug("Tool result payload: #{message.payload}")

      case tool_name
      when 'load_departments'
        handle_load_departments_result(message.payload)
      when 'generate_recommendations'
        handle_recommendations_result(message.payload, processing)
      when 'create_consolidated_departments'
        handle_consolidation_result(message.payload, processing)
      end
    end

    def handle_policy_message(message)
      logger.warn("Policy alert: #{message.payload}")
      puts "⚠️  Policy Alert: #{message.payload}"
    end

    def handle_audit_message(message)
      logger.info("Audit event: #{message.payload}")
      puts "📋 Audit: #{message.payload}"
    end

    def setup_message_handler(doge, processing, last_activity, message_count)
      doge.bus.subscribe do |message|
        message_count[0] += 1
        last_activity[0] = Time.now
        logger.debug("VSM Bus Message ##{message_count[0]}: kind=#{message.kind}, payload_size=#{message.payload.to_s.length}, meta=#{message.meta}")

        case message.kind
        when :assistant_delta
          handle_assistant_delta(message)
        when :assistant
          handle_assistant_message(message, processing)
        when :tool_call
          handle_tool_call(message)
        when :tool_result
          handle_tool_result(message, processing)
        when :policy
          handle_policy_message(message)
        when :audit
          handle_audit_message(message)
        else
          logger.debug("Unhandled message kind: #{message.kind}")
        end
      end
    end

    def setup_completion_detection(processing, last_activity)
      completion_timeout = 60
      logger.info("Starting simple completion detection")

      Async do
        while processing[0]
          Async::Task.current.sleep(5.0)

          current_time = Time.now
          elapsed = current_time - @total_start_time
          time_since_activity = current_time - last_activity[0]

          if time_since_activity > completion_timeout || elapsed > 300
            logger.info("Completion detected - elapsed: #{elapsed.round(2)}s, inactive: #{time_since_activity.round(2)}s")
            processing[0] = false
            break
          end
        end

        total_duration = Time.now - @total_start_time
        logger.info("Analysis completed in #{total_duration.round(2)}s")
        status_line("✅ Analysis complete!")
        sleep(0.5)
        restore_terminal
      end.wait
    end

  end
end
