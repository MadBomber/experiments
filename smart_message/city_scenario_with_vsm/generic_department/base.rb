#!/usr/bin/env ruby
# base.rb - VSM-based configurable city department template
#


module GenericDepartment
  # Main Generic Template Class
  class Base
  include Common::Logger
  include Common::StatusLine

  def initialize
    # Determine config file based on program name
    @config_file = determine_config_file

    unless File.exist?(@config_file)
      puts "❌ Configuration file not found: #{@config_file}"
      puts "🔍 Expected config file based on program name"
      exit(1)
    end

    @config = YAML.load_file(@config_file)
    @service_name = @config['department']['name']
    @status_line_prefix = @service_name

    @statistics = Hash.new(0)
    @start_time = Time.now
    @last_activity = Time.now
    @status_update_counter = 0

    # Use logger mixin consistently with other city services
    setup_logger(
      name: @service_name,
      level: (@config['logging']['level'] || 'info')
    )

    puts "\n" + "="*60
    puts "🚀 Starting #{@config['department']['display_name']}"
    puts "="*60
    puts "📁 Configuration: #{@config_file}"
    puts "🏷️ Service: #{@service_name}"
    puts "🕐 Started: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"

    logger.info("🚀 Starting #{@config['department']['display_name']}")
    logger.info("📁 Configuration loaded from: #{@config_file}")
    logger.info("🏷️ Service name: #{@service_name}")

    # Load required message classes dynamically
    load_message_classes

    # Initialize VSM capsule
    initialize_vsm_capsule

    # Setup message subscriptions
    setup_message_subscriptions

    # Setup health monitoring
    setup_health_monitoring

    # Setup periodic statistics logging
    setup_statistics_logging if @config['logging']['statistics_interval']

    puts "\n✅ #{@config['department']['display_name']} is fully operational"
    puts "="*60
    puts "💡 Department capabilities:"
    @config['capabilities'].each { |cap| puts "   ✔ #{cap}" }
    puts "-"*60
    puts "📡 Listening for messages... (Press Ctrl+C to stop)"
    puts "-"*60

    # Setup periodic status updates
    setup_status_updates

    logger.info("✅ #{@config['department']['display_name']} is fully operational")
    logger.info("🎯 Ready to handle: #{@config['capabilities'].join(', ')}")

    # Setup signal handlers for clean shutdown
    setup_signal_handlers

    # Start main loop
    main_loop
  end

  private

  def determine_config_file
    # Check for command line argument first
    if ARGV.length > 0
      department_name = ARGV[0]
      "#{department_name}.yml"
    else
      puts "You have not provided a customizing department name."
      logger.fatal "No customizing department name provided"
      exit(1)
    end
  end

  def load_message_classes
    logger.info("📦 Loading required message classes")

    # Always load health messages for monitoring
    require_message_class('health_check_message')
    require_message_class('health_status_message')

    # Load message classes based on subscriptions
    if @config['message_types'] && @config['message_types']['subscribes_to']
      @config['message_types']['subscribes_to'].each do |message_type|
        require_message_class(message_type) unless message_type == 'health_check_message'
      end
    end

    # Load message classes based on publications
    if @config['message_types'] && @config['message_types']['publishes']
      @config['message_types']['publishes'].each do |message_type|
        require_message_class(message_type)
      end
    end

    logger.info("✅ Message classes loaded successfully")
  rescue => e
    logger.error("❌ Failed to load message classes: #{e.message}")
    logger.debug("🔍 Error details: #{e.backtrace.first(3).join('\n')}")
  end

  def require_message_class(message_type)
    logger.debug("📦 Loading message class: #{message_type}")

    begin
      require_relative "../messages/#{message_type}"
      logger.debug("✅ Loaded: messages/#{message_type}")
    rescue LoadError => e
      logger.warn("⚠️ Could not load message class: messages/#{message_type} (#{e.message})")
    end
  end

  def initialize_vsm_capsule
    logger.info("🏗️ Initializing VSM capsule")

    # Capture config in local variable for use in DSL block
    config = @config

    @capsule = VSM::DSL.define(@service_name.to_sym) do
      identity klass: GenericDepartment::Identity, args: { config: config }
      governance klass: GenericDepartment::Governance, args: { config: config }
      intelligence klass: GenericDepartment::Intelligence, args: { config: config }
      operations klass: GenericDepartment::Operations, args: { config: config }
      coordination klass: VSM::Coordination
    end

    logger.info("✅ VSM capsule initialized and ready")
  end

  def setup_message_subscriptions
    return unless @config['message_types'] && @config['message_types']['subscribes_to']

    @config['message_types']['subscribes_to'].each do |message_type|
      # Skip health_check_message as it's handled by setup_health_monitoring
      next if message_type == 'health_check_message'
      setup_message_subscription(message_type)
    end
  end

  def setup_message_subscription(message_type)
    logger.info("📡 Setting up subscription to #{message_type}")

    begin
      # Convert snake_case to CamelCase for class name
      class_name = message_type.split('_').map(&:capitalize).join

      if defined?(Messages) && Messages.const_defined?(class_name)
        message_class = Messages.const_get(class_name)

        message_class.subscribe(to: @service_name) do |message|
          # Update last activity time
          @last_activity = Time.now

          logger.info("📨 Received #{message_type} from #{message._sm_header&.from || 'unknown'}")
          logger.debug("📝 Message details: #{message.inspect}")

          begin
            handle_message(message_type, message)
            @statistics[:messages_received] += 1
            logger.info("✅ Message processed successfully")
          rescue => e
            logger.error("🚨 Failed to handle #{message_type}: #{e.message}")
            @statistics[:message_handling_failures] += 1
          end

          # The status line will update automatically via the update_status_line thread
        end

        logger.info("✅ Successfully subscribed to #{message_type}")
      else
        logger.warn("⚠️ Message class #{class_name} not found for #{message_type}")
      end
    rescue => e
      logger.error("❌ Failed to setup subscription for #{message_type}: #{e.message}")
    end
  end

  def handle_message(message_type, message)
    logger.info("🎯 Processing #{message_type} message")

    # Convert message to hash for VSM processing
    message_data = message.respond_to?(:to_h) ? message.to_h : message.to_hash

    # Route to VSM Intelligence
    logger.debug("📤 Forwarding to VSM Intelligence")
    @capsule.bus.emit VSM::Message.new(
      kind: message_type.to_sym,
      payload: message_data,
      meta: {
        msg_id: message._sm_header&.msg_id || SecureRandom.uuid,
        from: message._sm_header&.from || 'unknown'
      }
    )

    logger.info("✅ Message forwarded to VSM successfully")
  end

  def setup_health_monitoring
    # Subscribe to health check messages if configured
    if @config['message_types'] &&
       @config['message_types']['subscribes_to'] &&
       @config['message_types']['subscribes_to'].include?('health_check_message')

      logger.info("💗 Setting up health monitoring")

      if defined?(Messages::HealthCheckMessage)
        puts "💗 Health monitoring enabled"

        Messages::HealthCheckMessage.subscribe(broadcast: true) do |message|
          respond_to_health_check(message)
        end
        logger.info("✅ Health monitoring active")
      end
    end
  end

  def respond_to_health_check(message)
    # Update last activity
    @last_activity = Time.now

    logger.info("💗 Received health check from #{message._sm_header&.from}")

    # Generate health status response
    if defined?(Messages::HealthStatusMessage)
      uptime = Time.now - @start_time
      success_rate = calculate_success_rate

      response = Messages::HealthStatusMessage.new(
        from: @service_name,
        to: message._sm_header&.from,
        check_id: message.check_id,
        service_name: @service_name,
        status: 'healthy',
        uptime_seconds: uptime.to_i,
        message_count: @statistics[:messages_received],
        last_activity: Time.now.iso8601,
        capabilities: @config['capabilities'] || []
      )

      response.publish
      logger.info("💗 Health status sent to #{message._sm_header&.from}")
      logger.info("   Metrics: #{@statistics[:messages_received]} msgs, #{success_rate}% success, uptime: #{format_duration(uptime)}")

      # Update statistics
      @statistics[:health_checks_responded] = (@statistics[:health_checks_responded] || 0) + 1

      # Don't print to console - let the status line handle display
      # The status line will update automatically via the update_status_line thread
    else
      logger.warn("⚠️ Messages::HealthStatusMessage not defined, cannot respond to health check")
    end
  end

  def setup_status_updates
    # Update status line every 5 seconds
    @status_thread = Thread.new do
      loop do
        sleep(5)
        update_status_line
      end
    end
  end

  def update_status_line
    uptime = Time.now - @start_time
    idle_time = Time.now - @last_activity

    status = if idle_time < 10
      "🟢 Active"
    elsif idle_time < 60
      "🟡 Idle"
    else
      "⚪ Waiting"
    end

    # Calculate success rate
    success_rate = calculate_success_rate

    # Get most active capability
    most_active_capability = get_most_active_capability

    # Calculate average response time
    avg_response_time = calculate_average_response_time

    # Build comprehensive status with department-specific stats (optimized for terminal width)
    status_parts = [
      status,
      "⏱#{format_duration(uptime)}",
      "📨#{@statistics[:messages_received]}"
    ]

    # Add successful operations if any
    if @statistics[:successful_operations] > 0
      status_parts << "✅#{@statistics[:successful_operations]}"
    end

    # Add failures only if they exist
    if @statistics[:failed_operations] > 0
      status_parts << "❌#{@statistics[:failed_operations]}"
    end

    # Add health checks if any responded
    if @statistics[:health_checks_responded] && @statistics[:health_checks_responded] > 0
      status_parts << "💗#{@statistics[:health_checks_responded]}"
    end

    # Add success rate if we have operations
    if (@statistics[:successful_operations] + @statistics[:failed_operations]) > 0
      status_parts << "📊#{success_rate}%"
    end

    # Add average response time if available and significant
    if avg_response_time > 0.1
      status_parts << "⚡#{avg_response_time.round(1)}s"
    end

    # Add most active capability if available (abbreviated)
    if most_active_capability
      cap_name = most_active_capability[:name].split('_').first.capitalize
      status_parts << "🎯#{cap_name}(#{most_active_capability[:count]})"
    end

    # Add health status indicator
    health = get_health_status
    status_parts << health

    # Use the status_line method from Common::StatusLine which respects @program_name
    status_text = status_parts.join(" ")
    status_line(status_text)
  end

  def setup_statistics_logging
    interval = @config['logging']['statistics_interval'].to_i

    logger.info("📊 Setting up statistics logging every #{interval} seconds")

    @stats_thread = Thread.new do
      loop do
        sleep(interval)
        log_department_statistics
        print_terminal_statistics
      end
    end
  end

  def print_terminal_statistics
    # Log statistics to file only - don't interfere with status line
    # Statistics are already shown in the status line
    log_department_statistics
  end

  def log_department_statistics
    uptime = Time.now - @start_time

    logger.info("📊 === DEPARTMENT STATISTICS ===")
    logger.info("⏰ Uptime: #{format_duration(uptime)}")
    logger.info("📨 Messages received: #{@statistics[:messages_received]}")
    logger.info("✅ Successful operations: #{@statistics[:successful_operations]}")
    logger.info("❌ Failed operations: #{@statistics[:failed_operations]}")

    if @statistics[:messages_received] > 0
      avg_processing_time = @statistics[:total_processing_time] / @statistics[:messages_received]
      logger.info("⚡ Average message processing time: #{avg_processing_time.round(3)}s")
    end

    # Log capability-specific statistics
    (@config['capabilities'] || []).each do |capability|
      executions = @statistics["#{capability}_executions"]
      if executions > 0
        total_time = @statistics["#{capability}_total_time"]
        avg_time = total_time / executions
        logger.info("🎯 #{capability}: #{executions} executions, avg time: #{avg_time.round(3)}s")
      end
    end

    logger.info("📊 ========================")
  end

  def setup_signal_handlers
    ['TERM', 'INT'].each do |signal|
      Signal.trap(signal) do
        # Clear status line
        print "\r" + " "*80 + "\r"
        puts "\n\n📡 Received #{signal} signal, shutting down #{@config['department']['display_name']}..."
        logger.info("📡 Received #{signal} signal, initiating shutdown...")
        shutdown_gracefully
      end
    end
  end

  def main_loop
    logger.info("🔄 Starting main service loop")

    loop do
      sleep(1)
      # Service continues running, handling messages via subscriptions
    end
  rescue Interrupt
    logger.info("🛑 Service interrupted")
  ensure
    shutdown_gracefully
  end

  def shutdown_gracefully
    # Clear status line
    print "\r" + " "*80 + "\r"

    logger.info("🛑 Shutting down #{@config['department']['display_name']}")
    puts "\n🛑 Shutting down #{@config['department']['display_name']}..."

    # Stop threads
    @status_thread&.kill
    @stats_thread&.kill

    # Log final statistics
    log_final_statistics

    # Print final stats to terminal
    print_final_terminal_stats

    # Cleanup VSM capsule (VSM capsules don't need explicit shutdown)

    puts "👋 #{@config['department']['display_name']} shutdown complete"
    logger.info("👋 #{@config['department']['display_name']} shutdown complete")
    exit(0)
  end

  def print_final_terminal_stats
    uptime = Time.now - @start_time
    success_rate = calculate_success_rate

    puts "\n" + "="*60
    puts "📊 Final Statistics"
    puts "="*60
    puts "  Total Uptime: #{format_duration(uptime)}"
    puts "  Messages Processed: #{@statistics[:messages_received]}"
    puts "  Successful Operations: #{@statistics[:successful_operations]}"
    puts "  Failed Operations: #{@statistics[:failed_operations]}"
    puts "  Success Rate: #{success_rate}%"
    puts "="*60
  end

  def log_final_statistics
    uptime = Time.now - @start_time

    logger.info("📊 === FINAL DEPARTMENT STATISTICS ===")
    logger.info("⏰ Total uptime: #{format_duration(uptime)}")
    logger.info("📨 Total messages processed: #{@statistics[:messages_received]}")
    logger.info("✅ Total successful operations: #{@statistics[:successful_operations]}")
    logger.info("❌ Total failed operations: #{@statistics[:failed_operations]}")

    success_rate = calculate_success_rate
    logger.info("🎯 Operations success rate: #{success_rate}%")

    logger.info("📊 ==============================")
  end

  def format_duration(seconds)
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    secs = seconds % 60

    if hours > 0
      "#{hours.to_i}h #{minutes.to_i}m #{secs.to_i}s"
    elsif minutes > 0
      "#{minutes.to_i}m #{secs.to_i}s"
    else
      "#{secs.to_i}s"
    end
  end

  def calculate_success_rate
    total_ops = @statistics[:successful_operations] + @statistics[:failed_operations]
    return 100.0 if total_ops == 0

    ((@statistics[:successful_operations].to_f / total_ops) * 100).round(1)
  end

  def get_most_active_capability
    capability_stats = {}

    # Collect execution counts for each capability
    (@config['capabilities'] || []).each do |capability|
      executions = @statistics["#{capability}_executions"]
      capability_stats[capability] = executions if executions > 0
    end

    return nil if capability_stats.empty?

    # Find the capability with the most executions
    most_active = capability_stats.max_by { |_name, count| count }
    {
      name: most_active[0],
      count: most_active[1]
    }
  end

  def calculate_average_response_time
    return 0.0 if @statistics[:messages_received] == 0 || @statistics[:total_processing_time] == 0

    (@statistics[:total_processing_time] / @statistics[:messages_received]).to_f
  end

  def get_health_status
    # Determine health based on recent activity and error rates
    idle_time = Time.now - @last_activity
    success_rate = calculate_success_rate

    if idle_time > 300 # 5 minutes
      "⚠️"  # Warning - very idle
    elsif success_rate < 80 && (@statistics[:successful_operations] + @statistics[:failed_operations]) > 5
      "🔥"  # Critical - low success rate with significant operations
    elsif success_rate < 95 && (@statistics[:successful_operations] + @statistics[:failed_operations]) > 10
      "⚠️"  # Warning - moderate success rate
    else
      "OK"  # Healthy
    end
  end
  end
end

# Start the generic template service
if __FILE__ == $0
  GenericDepartment::Base.new
end
