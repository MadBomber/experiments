# generic_department/intelligence.rb

module GenericDepartment

  # VSM Intelligence Component for Generic Department
  class Intelligence < VSM::Intelligence
    include Common::Logger
    include Common::StatusLine

    def initialize(config:)
      @config = config
      @service_name = config['department']['name']
      @status_line_prefix = @service_name
      @statistics = Hash.new(0)

      logger.info('🧠 Initializing Intelligence system')

      # Setup AI if configured
      setup_ai if @config['ai_analysis'] && @config['ai_analysis']['enabled']

      super(driver: nil)
      logger.info('✅ Intelligence system ready')
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

      logger.info('🤖 Setting up AI analysis')
      @ai_available = true
    rescue StandardError => e
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

      'processed'
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
end
