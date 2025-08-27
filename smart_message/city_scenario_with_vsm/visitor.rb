#!/usr/bin/env ruby

require_relative 'smart_message/lib/smart_message'
require 'ruby_llm'
require 'json'

require_relative 'common/logger'
require_relative 'common/status_line'

# Dynamically require all message files in the messages directory
Dir[File.join(__dir__, 'messages', '*.rb')].each { |file| require file }

class Visitor
  include Common::Logger
  include Common::StatusLine

  def initialize(home_town = nil)
    @home_town = home_town || generate_random_home_town
    @service_name = "visitor-#{@home_town.gsub(/\s+/, '-').downcase}"
    @status_line_prefix = "from #{@home_town}"

    setup_ai
    logger.info("Visitor from #{@home_town} initialized - AI-powered message generation system ready")
  end


  def setup_ai
    # Initialize the AI model for intelligent message selection
    begin
      configure_rubyllm
      # RubyLLM.chat returns a Chat instance, we can use it directly
      @llm = RubyLLM.chat
      @ai_available = true
      logger.info("AI model initialized for message analysis")
    rescue => e
      @ai_available = false
      logger.warn("AI model not available: #{e.message}. Using fallback logic.")
    end
  end


  def configure_rubyllm
    RubyLLM.configure do |config|
      config.anthropic_api_key  = ENV.fetch('ANTHROPIC_API_KEY', nil)
      config.deepseek_api_key   = ENV.fetch('DEEPSEEK_API_KEY', nil)
      config.gemini_api_key     = ENV.fetch('GEMINI_API_KEY', nil)
      config.gpustack_api_key   = ENV.fetch('GPUSTACK_API_KEY', nil)
      config.mistral_api_key    = ENV.fetch('MISTRAL_API_KEY', nil)
      config.openrouter_api_key = ENV.fetch('OPENROUTER_API_KEY', nil)
      config.perplexity_api_key = ENV.fetch('PERPLEXITY_API_KEY', nil)

      # These providers require a little something extra
      config.openai_api_key         = ENV.fetch('OPENAI_API_KEY', nil)
      config.openai_organization_id = ENV.fetch('OPENAI_ORGANIZATION_ID', nil)
      config.openai_project_id      = ENV.fetch('OPENAI_PROJECT_ID', nil)

      config.bedrock_api_key       = ENV.fetch('BEDROCK_ACCESS_KEY_ID', nil)
      config.bedrock_secret_key    = ENV.fetch('BEDROCK_SECRET_ACCESS_KEY', nil)
      config.bedrock_region        = ENV.fetch('BEDROCK_REGION', nil)
      config.bedrock_session_token = ENV.fetch('BEDROCK_SESSION_TOKEN', nil)

      # Ollama is based upon the OpenAI API so it needs to over-ride a few things
      config.ollama_api_base = ENV.fetch('OLLAMA_API_BASE', nil)

      # --- Custom OpenAI Endpoint ---
      # Use this for Azure OpenAI, proxies, or self-hosted models via OpenAI-compatible APIs.
      config.openai_api_base = ENV.fetch('OPENAI_API_BASE', nil) # e.g., "https://your-azure.openai.azure.com"

      # --- Default Models ---
      # Used by RubyLLM.chat, RubyLLM.embed, RubyLLM.paint if no model is specified.
      # config.default_model            = 'gpt-4.1-nano'            # Default: 'gpt-4.1-nano'
      # config.default_embedding_model  = 'text-embedding-3-small'  # Default: 'text-embedding-3-small'
      # config.default_image_model      = 'dall-e-3'                # Default: 'dall-e-3'

      # --- Connection Settings ---
      # config.request_timeout            = 120 # Request timeout in seconds (default: 120)
      # config.max_retries                = 3   # Max retries on transient network errors (default: 3)
      # config.retry_interval             = 0.1 # Initial delay in seconds (default: 0.1)
      # config.retry_backoff_factor       = 2   # Multiplier for subsequent retries (default: 2)
      # config.retry_interval_randomness  = 0.5 # Jitter factor (default: 0.5)

      # --- Logging Settings ---
      config.log_file   = 'log/ruby_llm.log'
      config.log_level = :debug # debug level can also be set to debug by setting RUBYLLM_DEBUG envar to true
    end
  end


  def generate_observation_scenario
    # Various scenarios the visitor might observe
    scenarios = [
      {
        type: 'crime',
        description: 'Witnessed armed robbery at convenience store',
        context: 'A visitor witnessed an armed robbery at a local convenience store. Two suspects with weapons.'
      },
      {
        type: 'fire',
        description: 'Smoke coming from apartment building',
        context: 'A visitor noticed heavy smoke coming from a third-floor apartment window.'
      },
      {
        type: 'accident',
        description: 'Multi-car collision at intersection',
        context: 'A visitor witnessed a three-car collision at a busy intersection. People may be injured.'
      },
      {
        type: 'medical',
        description: 'Person collapsed on sidewalk',
        context: 'A visitor found an elderly person who collapsed on the sidewalk, unconscious but breathing.'
      },
      {
        type: 'suspicious',
        description: 'Someone breaking into parked cars',
        context: 'A visitor observed someone systematically checking car doors and breaking into unlocked vehicles.'
      },
      {
        type: 'hazmat',
        description: 'Chemical smell from abandoned truck',
        context: 'A visitor noticed a strong chemical odor coming from an abandoned delivery truck.'
      },
      {
        type: 'rescue',
        description: 'Child stuck on roof',
        context: 'A visitor spotted a child stuck on a roof, unable to get down safely.'
      }
    ]

    scenarios.sample
  end


  def report_observation(scenario = nil)
    scenario ||= generate_observation_scenario
    logger.info("Starting observation reporting process for: #{scenario[:type]}")

    # Step 1: Collect all message descriptions
    message_descriptions = collect_message_descriptions
    logger.info("Collected descriptions for #{message_descriptions.size} message types")

    # Step 2: Ask AI to select appropriate message for the scenario
    selected_message_class = ask_ai_for_message_selection(message_descriptions, scenario)
    logger.info("AI selected message type: #{selected_message_class}")

    # Step 3: Collect property descriptions for selected message
    property_descriptions = collect_property_descriptions(selected_message_class)
    logger.info("Collected #{property_descriptions.size} properties for #{selected_message_class}")

    # Step 4: Generate message instance using AI with retry on validation errors
    max_retries = 3
    retry_count = 0
    message_instance = nil
    validation_errors = []

    while retry_count < max_retries
      message_instance = generate_message_instance(selected_message_class, property_descriptions, validation_errors, scenario)
      logger.info("Generated message instance with AI-provided values (attempt #{retry_count + 1})")

      # Try to publish the message
      begin
        publish_message(message_instance)
        logger.info("Successfully published robbery report message")
        break
      rescue => e
        retry_count += 1
        error_msg = e.message
        logger.warn("Publishing failed (attempt #{retry_count}): #{error_msg}")

        # Parse validation error for specific property and valid values
        validation_error_details = parse_validation_error(error_msg)

        if validation_error_details
          # Build detailed error context for AI
          validation_errors = [
            "Property '#{validation_error_details[:property]}' has invalid value.",
            "Error: #{validation_error_details[:message]}",
            validation_error_details[:valid_values] ? "Valid values are: #{validation_error_details[:valid_values]}" : nil
          ].compact

          if retry_count < max_retries && @ai_available
            logger.info("Attempting to fix validation error with AI assistance")
            logger.info("Error details: property=#{validation_error_details[:property]}, valid_values=#{validation_error_details[:valid_values]}")
            # Continue to next iteration to regenerate with error context
          else
            logger.error("Max retries reached or AI unavailable. Cannot fix validation error.")
            raise
          end
        else
          # Non-validation error, re-raise
          logger.error("Non-validation error encountered: #{error_msg}")
          raise
        end
      end
    end

    message_instance
  end


  def run_continuous(interval_seconds = 15)
    puts "👁️  Smart Visitor - AI-Powered Observation Reporting System"
    puts "   Visitor from: #{@home_town}"
    puts "   Continuously observing the city and reporting incidents"
    puts "   Generating new observations every #{interval_seconds} seconds"
    puts "   Press Ctrl+C to stop\n\n"

    observation_count = 0

    # Set up signal handler for graceful shutdown
    Signal.trap('INT') do
      puts "\n\n👋 Visitor signing off after #{observation_count} observations."
      logger.info("Visitor stopped after #{observation_count} observations")
      exit(0)
    end

    Signal.trap('TERM') do
      puts "\n👋 Visitor terminated after #{observation_count} observations."
      exit(0)
    end

    loop do
      observation_count += 1
      scenario = generate_observation_scenario

      puts "\n" + "="*60
      puts "📍 OBSERVATION ##{observation_count} - #{Time.now.strftime('%H:%M:%S')}"
      puts "   Type: #{scenario[:type].upcase}"
      puts "   What I see: #{scenario[:description]}"
      puts "   Reporting to emergency services..."

      begin
        message = report_observation(scenario)

        if message
          puts "   ✅ Report sent via #{message.class.to_s.split('::').last}"
          logger.info("Observation ##{observation_count} reported successfully via #{message.class}")
        else
          puts "   ⚠️ Unable to send report"
          logger.warn("Observation ##{observation_count} could not be reported")
        end
      rescue => e
        puts "   ❌ Error: #{e.message}"
        logger.error("Error reporting observation ##{observation_count}: #{e.message}")
      end

      puts "   💤 Waiting #{interval_seconds} seconds before next observation..."
      sleep(interval_seconds)
    end
  end

  private

  def generate_random_home_town
    home_towns = [
      'Chicago', 'Denver', 'Seattle', 'Boston', 'Atlanta',
      'Phoenix', 'Detroit', 'Portland', 'Nashville', 'Miami',
      'Austin', 'San Diego', 'Cleveland', 'Pittsburgh', 'Tampa',
      'Kansas City', 'New Orleans', 'Salt Lake City', 'Memphis', 'Tucson'
    ]
    home_towns.sample
  end

  def parse_validation_error(error_message)
    # Parse validation errors like:
    # "Messages::Emergency911Message#emergency_type: Emergency type must be one of: fire, medical, crime, accident, hazmat, rescue, other"
    # "Messages::SilentAlarmMessage#alarm_type: Alarm type must be: robbery, vault_breach, suspicious_activity"

    # Try to match the pattern: ClassName#property: message
    if error_message =~ /Messages::(\w+)#(\w+):\s*(.+)/
      class_name = $1
      property = $2
      message = $3

      # Extract valid values if present
      valid_values = nil
      if message =~ /must be(?:\s+one\s+of)?:\s*(.+)/i
        values_str = $1.strip
        # Clean up the values string and split
        valid_values = values_str.split(/,\s*/).map(&:strip)
      end

      return {
        class_name: class_name,
        property: property,
        message: message,
        valid_values: valid_values
      }
    end

    # Try alternate format for required properties
    if error_message =~ /property\s+'(\w+)'\s+is\s+required/i
      return {
        property: $1,
        message: error_message,
        valid_values: nil
      }
    end

    # Check if it's a validation error even if we can't parse details
    if error_message.include?("ValidationError") || error_message.include?("must be") || error_message.include?("required")
      return {
        property: "unknown",
        message: error_message,
        valid_values: nil
      }
    end

    nil
  end

  def collect_message_descriptions
    logger.info("Scanning Messages module for available message classes")

    message_descriptions = {}

    # Get all message classes from the Messages module
    Messages.constants.each do |const_name|
      const = Messages.const_get(const_name)

      # Check if it's a SmartMessage class
      if const.is_a?(Class) && const < SmartMessage::Base
        description = const.respond_to?(:description) ? const.description : "No description available"
        message_descriptions[const_name.to_s] = {
          class: const,
          description: description
        }
        logger.info("Found message class: #{const_name} - #{description[0..100]}...")
      end
    end

    message_descriptions
  end

  def ask_ai_for_message_selection(message_descriptions, scenario = nil)
    logger.info("Asking AI to select appropriate message type for robbery reporting")

    if @ai_available
      # Build prompt for AI
      descriptions_text = message_descriptions.map do |class_name, info|
        "#{class_name}: #{info[:description]}"
      end.join("\n\n")

      scenario_context = scenario ? scenario[:context] : "A visitor witnessed a robbery at a local business."

      prompt = <<~PROMPT
        You are helping a visitor to a city report an incident they witnessed.

        Scenario: #{scenario_context}

        Below are the available message types in the city's emergency communication system:

        #{descriptions_text}

        Based on this scenario, which message type would be most appropriate for reporting this incident?
        Note: For a visitor witnessing an incident, Emergency911Message is usually most appropriate.

        Please respond with ONLY the exact class name (e.g., "Emergency911Message") - no additional text or explanation.
      PROMPT

      logger.info("Sending prompt to AI for message type selection")
      logger.info("=== AI PROMPT ===\n#{prompt}\n=== END PROMPT ===")
      begin
        response = @llm.ask(prompt)
        logger.info("=== AI RESPONSE ===\n#{response}\n=== END RESPONSE ===")
        selected_class_name = response.content.strip

        logger.info("AI response processed: #{selected_class_name}")

        # Validate the AI's selection
        if message_descriptions[selected_class_name]
          selected_class = message_descriptions[selected_class_name][:class]
          logger.info("AI selection validated: #{selected_class}")
          return selected_class
        end
      rescue => e
        logger.error("AI request failed: #{e.message}")
      end
    end

    # Fallback logic when AI is not available or fails
    logger.info("Using fallback message selection logic")

    # Look for Emergency911Message first (most appropriate for general robbery reporting by witnesses)
    if message_descriptions['Emergency911Message']
      logger.info("Selected Emergency911Message for robbery reporting")
      return message_descriptions['Emergency911Message'][:class]
    end

    # If no Emergency911Message, look for SilentAlarmMessage (for bank-specific robberies)
    if message_descriptions['SilentAlarmMessage']
      logger.info("Selected SilentAlarmMessage as fallback for robbery reporting")
      return message_descriptions['SilentAlarmMessage'][:class]
    end

    # If neither, find any message with "alarm" or "emergency" in the name
    emergency_message = message_descriptions.find { |name, _| name.downcase.include?('emergency') || name.downcase.include?('911') }
    if emergency_message
      logger.info("Selected #{emergency_message[0]} as emergency message")
      return emergency_message[1][:class]
    end

    # Last resort: use first available message
    first_message = message_descriptions.first
    if first_message
      logger.info("Using first available message type: #{first_message[0]}")
      return first_message[1][:class]
    end

    raise "No valid message type found for robbery reporting"
  end

  def collect_property_descriptions(message_class)
    logger.info("Collecting property descriptions for #{message_class}")

    # Get property descriptions and validation info
    if message_class.respond_to?(:property_descriptions)
      property_descriptions = message_class.property_descriptions
      logger.info("Retrieved #{property_descriptions.size} property descriptions from class method")

      # Enhance descriptions with validation constraints
      enhanced_descriptions = {}

      property_descriptions.each do |prop, desc|
        enhanced_desc = desc.to_s

        # Add validation info if available
        if message_class.respond_to?(:property_validations) && message_class.property_validations[prop]
          validation = message_class.property_validations[prop]
          if validation[:validation_message]
            enhanced_desc += " (#{validation[:validation_message]})"
          end
        end

        # Check for constant arrays that define valid values (e.g., VALID_ALARM_TYPES)
        const_name = "VALID_#{prop.to_s.upcase}S"
        if message_class.const_defined?(const_name)
          valid_values = message_class.const_get(const_name)
          enhanced_desc += " Valid values: #{valid_values.join(', ')}"
        end

        enhanced_descriptions[prop] = enhanced_desc
        logger.info("Property: #{prop} - #{enhanced_desc}")
      end

      return enhanced_descriptions
    else
      logger.warn("Property descriptions method not available on #{message_class}")
      return {}
    end
  end

  def generate_message_instance(message_class, property_descriptions, validation_errors = [], scenario = nil)
    logger.info("Asking AI to generate property values for #{message_class}")

    property_values = nil

    if @ai_available
      # Build prompt for AI to generate property values
      properties_text = property_descriptions.map do |prop, desc|
        "#{prop}: #{desc}"
      end.join("\n")

      # Add error context if this is a retry
      error_context = ""
      if validation_errors.any?
        error_context = <<~ERROR

          ⚠️ PREVIOUS ATTEMPT FAILED WITH VALIDATION ERRORS:
          #{validation_errors.map { |e| "  • #{e}" }.join("\n")}

          REQUIRED FIX: You MUST correct these specific properties with valid values.
          Only change the properties mentioned in the errors above.
          Keep all other property values the same.
        ERROR
      end

      scenario_context = scenario ? scenario[:context] : "A visitor witnessed a robbery at a local business."
      scenario_desc = scenario ? scenario[:description] : "Witnessed armed robbery"

      prompt = <<~PROMPT
        You are helping generate an emergency report message for an incident a visitor witnessed.

        Scenario: #{scenario_context}

        Please provide values for the following properties of a #{message_class} message:

        #{properties_text}

        Context: #{scenario_desc}
        The visitor is reporting this incident, so the 'from' field should be set to 'visitor'.

        IMPORTANT: Some properties have validation constraints shown in parentheses or as "Valid values". You MUST use only the specified valid values for those properties.
        #{error_context}
        Please respond with a JSON object containing the property values. Use realistic values that make sense for a robbery report.
        For timestamps, use the current date/time format in ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ).

        Example format:
        {
          "property1": "value1",
          "property2": "value2"
        }
      PROMPT

      logger.info("Sending property generation prompt to AI")
      logger.info("=== AI PROPERTY PROMPT ===\n#{prompt}\n=== END PROMPT ===")
      begin
        response = @llm.ask(prompt)
        logger.info("=== AI PROPERTY RESPONSE ===\n#{response}\n=== END RESPONSE ===")

        # Parse AI response as JSON
        property_values = JSON.parse(response.content)
        logger.info("Successfully parsed AI response as JSON")
      rescue JSON::ParserError => e
        logger.error("Failed to parse AI response as JSON: #{e.message}")
        property_values = nil
      rescue => e
        logger.error("AI request failed: #{e.message}")
        property_values = nil
      end
    end

    # Fallback to hardcoded values if AI failed
    if property_values.nil?
      logger.info("Using fallback property values")
      property_values = generate_fallback_values(message_class, validation_errors)
    end

    # Ensure 'from' is set to visitor with home town
    property_values['from'] = @service_name

    # Create message instance using keyword arguments
    begin
      # Convert hash to keyword arguments
      kwargs = property_values.transform_keys(&:to_sym)
      message_instance = message_class.new(**kwargs)
      logger.info("Successfully created message instance")
      return message_instance
    rescue => e
      logger.error("Failed to create message instance: #{e.message}")
      # Try with fallback values
      fallback_values = generate_fallback_values(message_class)
      fallback_values['from'] = @service_name
      fallback_kwargs = fallback_values.transform_keys(&:to_sym)
      message_instance = message_class.new(**fallback_kwargs)
      logger.info("Created message instance with fallback values")
      return message_instance
    end
  end

  def generate_fallback_values(message_class, validation_errors = [])
    logger.info("Generating fallback values for #{message_class}")

    # Basic fallback values for common message types
    case message_class.to_s
    when /Emergency911Message/
      {
        'caller_name' => 'Anonymous Visitor',
        'caller_phone' => '555-0123',
        'caller_location' => '456 Oak Street',
        'emergency_type' => 'crime',
        'description' => 'Witnessed armed robbery at local store',
        'severity' => 'high',
        'injuries_reported' => false,
        'fire_involved' => false,
        'weapons_involved' => true,
        'suspects_on_scene' => true,
        'timestamp' => Time.now.iso8601,
        'from' => @service_name,
        'to' => '911'
      }
    when /SilentAlarmMessage/
      {
        'bank_name' => 'First National Bank',
        'location' => '123 Main Street',
        'alarm_type' => 'robbery',
        'timestamp' => Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        'severity' => 'high',
        'details' => 'Visitor reported armed robbery in progress',
        'from' => @service_name
      }
    when /PoliceDispatchMessage/
      {
        'dispatch_id' => SecureRandom.hex(4),
        'units_assigned' => ['Unit-101', 'Unit-102'],
        'location' => '123 Main Street',
        'incident_type' => 'robbery',
        'priority' => 'emergency',
        'estimated_arrival' => '3 minutes',
        'timestamp' => Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        'from' => @service_name
      }
    else
      {
        'timestamp' => Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        'details' => 'Visitor reported robbery incident',
        'from' => @service_name
      }
    end
  end

  def publish_message(message_instance)
    logger.info("Publishing message: #{message_instance.class}")

    begin
      message_instance.publish
      logger.info("Message published successfully to Redis transport")

      # Log the message content for debugging
      logger.info("Published message content: #{message_instance.to_h}")
    rescue => e
      logger.error("Failed to publish message: #{e.message}")
      raise
    end
  end
end

# Main execution
if __FILE__ == $0
  begin
    # Allow specifying home town as command line argument
    home_town = ARGV[0] unless ARGV[0] == '--once' || ARGV[0] == '-o' || ARGV[0]&.match?(/^\d+$/)
    visitor = Visitor.new(home_town)

    # Check for command-line arguments
    if ARGV.include?('--once') || ARGV.include?('-o')
      # Single observation mode
      puts "🎯 Smart Visitor - Single Observation Mode"
      puts "   From: #{visitor.instance_variable_get(:@home_town)}"
      scenario = visitor.generate_observation_scenario
      puts "   Observing: #{scenario[:description]}"

      message = visitor.report_observation(scenario)

      if message
        puts "\n✅ Report successfully generated and published!"
        puts "   Message Type: #{message.class}"
        puts "   Check visitor.log for details"
      end
    else
      # Continuous mode (default)
      # If first arg is a number and not a city name, use it as interval
      interval_arg = ARGV.find { |arg| arg.match?(/^\d+$/) }
      interval = interval_arg&.to_i || 15
      visitor.run_continuous(interval)
    end
  rescue => e
    puts "\n❌ Error in visitor program: #{e.message}"
    puts "   Check visitor.log for details"
    exit(1)
  end
end
