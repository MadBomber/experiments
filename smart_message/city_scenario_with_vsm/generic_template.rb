#!/usr/bin/env ruby
# generic_template.rb - VSM-based configurable city department template
#
# This template program uses YAML configuration to become any type of city department.
# When copied by city_council.rb, it reads its matching .yml config file for behavior.

require_relative 'smart_message/lib/smart_message'
require_relative 'common/logger'
require_relative 'vsm/lib/vsm'
require 'yaml'
require 'fileutils'

# VSM Identity Component for Generic Department
class GenericDepartmentIdentity < VSM::Identity
  include Common::Logger

  def initialize(config)
    @config = config
    @service_name = config['department']['name']

    logger.info("🏛️ Initializing #{config['department']['display_name']} Identity")
    logger.info("📋 Department capabilities: #{config['capabilities'].join(', ')}")
    logger.info("🎯 Department purpose: #{config['department']['description']}")

    super(
      identity: config['department']['name'],
      invariants: config['department']['invariants'] || [
        "serve citizens efficiently",
        "respond to emergencies promptly",
        "maintain operational readiness"
      ]
    )

    logger.info("✅ Identity system initialized successfully")
  end
end

# VSM Governance Component for Generic Department
class GenericDepartmentGovernance < VSM::Governance
  include Common::Logger

  def initialize(config)
    @config = config
    @service_name = config['department']['name']

    logger.info("⚖️ Initializing Governance system")
    super()

    logger.info("✅ Governance policies established")
  end

  def validate_action(action, context = {})
    logger.debug("⚖️ Validating action: #{action}")

    # Basic validation rules
    return false if action.nil? || action.empty?

    # Check if action is within department capabilities
    if @config['capabilities'] && !@config['capabilities'].include?(action)
      logger.warn("❌ Action #{action} not in department capabilities")
      return false
    end

    logger.debug("✅ Action #{action} validated")
    true
  end
end

# VSM Intelligence Component for Generic Department
class GenericDepartmentIntelligence < VSM::Intelligence
  include Common::Logger

  def initialize(config)
    @config = config
    @service_name = config['department']['name']
    @statistics = Hash.new(0)

    logger.info("🧠 Initializing Intelligence system")

    # Setup AI if configured
    setup_ai if @config['ai_analysis'] && @config['ai_analysis']['enabled']

    super()
    logger.info("✅ Intelligence system ready")
  end

  def handle(message, bus:, **)
    return false unless message.kind

    logger.info("🧠 Intelligence received message: kind=#{message.kind}")
    logger.debug("📝 Message payload: #{message.payload.inspect}")

    start_time = Time.now

    # Find routing rule for this message type
    rule = find_routing_rule(message.kind.to_s)

    if rule
      logger.info("📐 Applied routing rule: #{rule['condition'] || 'always'}")
      logger.info("⚡ Message priority: #{rule['priority'] || 'normal'}")

      result = process_with_priority(message, rule['priority'] || 'normal', bus)

      processing_time = Time.now - start_time
      logger.info("⏱️ Message processed in #{processing_time.round(3)}s")

      @statistics[:messages_processed] += 1
      @statistics[:total_processing_time] += processing_time

      true
    else
      logger.warn("❌ No routing rule found for message kind: #{message.kind}")
      @statistics[:unhandled_messages] += 1
      false
    end
  end

  private

  def setup_ai
    return unless defined?(RubyLLM)

    logger.info("🤖 Setting up AI analysis")
    @ai_available = true
  rescue => e
    logger.warn("⚠️ AI setup failed: #{e.message}")
    @ai_available = false
  end

  def find_routing_rule(message_kind)
    return nil unless @config['routing_rules']

    rules = @config['routing_rules'][message_kind]
    return nil unless rules

    # Return first rule (could add condition evaluation later)
    rules.is_a?(Array) ? rules.first : rules
  end

  def process_with_priority(message, priority, bus)
    logger.info("🎯 Processing message with priority: #{priority}")

    # Emit to operations for handling
    bus.emit VSM::Message.new(
      kind: :execute_capability,
      payload: {
        action: determine_action(message),
        message_data: message.payload,
        priority: priority
      }
    )

    "processed"
  end

  def determine_action(message)
    # Map message types to actions based on config
    message_type = message.kind.to_s

    if @config['message_actions'] && @config['message_actions'][message_type]
      @config['message_actions'][message_type]
    else
      # Default action based on message type
      "handle_#{message_type}"
    end
  end
end

# VSM Operations Component for Generic Department
class GenericDepartmentOperations < VSM::Operations
  include Common::Logger

  def initialize(config)
    @config = config
    @service_name = config['department']['name']
    @capabilities = config['capabilities'] || []
    @statistics = Hash.new(0)

    logger.info("🔧 Initializing operations for #{config['department']['name']}")
    logger.info("⚡ Available capabilities: #{@capabilities.join(', ')}")

    super()
    setup_capabilities

    logger.info("✅ Operations system ready with #{@capabilities.length} capabilities")
  end

  def handle(message, bus:, **)
    return false unless message.kind == :execute_capability

    payload = message.payload
    action = payload[:action]

    logger.info("🎯 Executing capability: #{action}")
    logger.debug("📋 Capability data: #{payload[:message_data]}")

    start_time = Time.now

    begin
      result = execute_capability(action, payload[:message_data], payload[:priority])

      execution_time = Time.now - start_time
      logger.info("✅ Capability #{action} completed in #{execution_time.round(3)}s")

      @statistics["#{action}_executions"] += 1
      @statistics["#{action}_total_time"] += execution_time
      @statistics[:successful_operations] += 1

      true
    rescue => e
      execution_time = Time.now - start_time
      logger.error("🚨 Capability #{action} failed after #{execution_time.round(3)}s")
      logger.error("❌ Error: #{e.message}")
      logger.debug("🔍 Error backtrace: #{e.backtrace.join('\n')}")

      @statistics["#{action}_failures"] += 1
      @statistics[:failed_operations] += 1

      false
    end
  end

  private

  def setup_capabilities
    @capabilities.each do |capability|
      logger.debug("🔧 Setting up capability: #{capability}")
    end
  end

  def execute_capability(action, message_data, priority)
    logger.info("🎯 Executing action: #{action} with priority: #{priority}")

    # Get action configuration if available
    action_config = @config['action_configs'] && @config['action_configs'][action]

    if action_config
      logger.debug("⚙️ Action config: #{action_config}")
      execute_configured_action(action, message_data, action_config)
    else
      execute_default_action(action, message_data)
    end
  end

  def execute_configured_action(action, message_data, action_config)
    logger.info("⚙️ Executing configured action: #{action}")

    # Generate response if template provided
    if action_config['response_template']
      response = generate_response(action_config['response_template'], message_data)
      logger.info("📤 Generated response: #{response}")

      # Publish response if configured
      if action_config['publish_response']
        publish_response(response, action_config, message_data)
      end
    end

    # Execute additional actions if configured
    if action_config['additional_actions']
      action_config['additional_actions'].each do |additional_action|
        logger.info("➡️ Executing additional action: #{additional_action}")
        execute_additional_action(additional_action, message_data)
      end
    end

    "configured_action_completed"
  end

  def execute_default_action(action, message_data)
    logger.info("🔧 Executing default action: #{action}")

    # Basic acknowledgment
    logger.info("📨 Received #{action} request")
    logger.debug("📋 Request data: #{message_data}")

    "default_action_completed"
  end

  def generate_response(template, data)
    # Simple template substitution
    response = template.dup
    data.each do |key, value|
      response.gsub!("{{#{key}}}", value.to_s)
    end
    response
  end

  def publish_response(response, action_config, message_data)
    logger.info("📤 Publishing response message")

    # Could publish response message here
    # For now, just log it
    logger.info("📢 Response: #{response}")
  end

  def execute_additional_action(action, message_data)
    logger.info("➡️ Additional action: #{action}")
    # Implementation for additional actions
  end
end

# Main Generic Template Class
class GenericTemplate
  include Common::Logger

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
    @statistics = Hash.new(0)
    @start_time = Time.now

    # Use logger mixin consistently with other city services
    setup_logger(
      service_name: @service_name,
      log_level: @config['logging']['level'] || 'info'
    )

    logger.info("🚀 Starting #{@config['department']['display_name']}")
    logger.info("📁 Configuration loaded from: #{@config_file}")
    logger.info("🏷️ Service name: #{@service_name}")

    # Initialize VSM capsule
    initialize_vsm_capsule

    # Setup message subscriptions
    setup_message_subscriptions

    # Setup health monitoring
    setup_health_monitoring

    # Setup periodic statistics logging
    setup_statistics_logging if @config['logging']['statistics_interval']

    logger.info("✅ #{@config['department']['display_name']} is fully operational")
    logger.info("🎯 Ready to handle: #{@config['capabilities'].join(', ')}")

    # Setup signal handlers for clean shutdown
    setup_signal_handlers

    # Start main loop
    main_loop
  end

  private

  def determine_config_file
    # Get program name without extension
    program_name = File.basename($0, '.rb')
    "#{program_name}.yml"
  end

  def initialize_vsm_capsule
    logger.info("🏗️ Initializing VSM capsule")

    @capsule = VSM::DSL.define(@service_name.to_sym) do
      identity klass: GenericDepartmentIdentity, args: [@config]
      governance klass: GenericDepartmentGovernance, args: [@config]
      intelligence klass: GenericDepartmentIntelligence, args: [@config]
      operations klass: GenericDepartmentOperations, args: [@config]
      coordination klass: VSM::Coordination
    end

    @capsule.start
    logger.info("✅ VSM capsule initialized and started")
  end

  def setup_message_subscriptions
    return unless @config['message_types'] && @config['message_types']['subscribes_to']

    @config['message_types']['subscribes_to'].each do |message_type|
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
          logger.info("📨 Received #{message_type} from #{message._sm_header&.from || 'unknown'}")
          logger.debug("📝 Message details: #{message.inspect}")

          begin
            handle_message(message_type, message)
            @statistics[:messages_received] += 1
          rescue => e
            logger.error("🚨 Failed to handle #{message_type}: #{e.message}")
            @statistics[:message_handling_failures] += 1
          end
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
        Messages::HealthCheckMessage.subscribe(to: @service_name) do |message|
          respond_to_health_check(message)
        end
        logger.info("✅ Health monitoring active")
      end
    end
  end

  def respond_to_health_check(message)
    logger.debug("💗 Received health check from #{message._sm_header&.from}")

    # Generate health status response
    if defined?(Messages::HealthStatusMessage)
      uptime = Time.now - @start_time

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
      logger.debug("💗 Health status sent to #{message._sm_header&.from}")
    end
  end

  def setup_statistics_logging
    interval = @config['logging']['statistics_interval'].to_i

    logger.info("📊 Setting up statistics logging every #{interval} seconds")

    @stats_thread = Thread.new do
      loop do
        sleep(interval)
        log_department_statistics
      end
    end
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
    logger.info("🛑 Shutting down #{@config['department']['display_name']}")

    # Stop statistics thread
    @stats_thread&.kill

    # Log final statistics
    log_final_statistics

    # Cleanup VSM capsule
    @capsule&.shutdown

    logger.info("👋 #{@config['department']['display_name']} shutdown complete")
    exit(0)
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
end

# Start the generic template service
if __FILE__ == $0
  GenericTemplate.new
end
