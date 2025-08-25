#!/usr/bin/env ruby
# city_council/intelligence.rb
# CityCouncil Intelligence Component - VSM Intelligence Subsystem

require_relative '../smart_message/lib/smart_message'
require_relative '../vsm/lib/vsm'
require 'ruby_llm'
require 'json'
require 'digest'

require_relative '../common/logger'

# Load all existing message types
Dir[File.join(__dir__, '..', 'messages', '*.rb')].each { |file| require file }

module CityCouncil
  # CityCouncil VSM Intelligence Component
  # Focuses on environmental scanning, analysis, and decision making
  class Intelligence < VSM::Intelligence
    include Common::Logger

    def initialize(council:, **)
      @council = council
      @service_name = 'city_council-intelligence'
      @analysis_cache = {}
      setup_ai
    end

    def handle(message, bus:, **)
      return false unless message.kind == :user || message.kind == :service_request

      logger.info("Intelligence: Received message: kind=#{message.kind}, payload=#{message.payload}")

      # Check if this is a request for a new service
      if needs_new_service?(message.payload)
        logger.info("Intelligence: Analyzing request for new service: #{message.payload}")

        # Extract service requirements using intelligence analysis
        service_spec = analyze_service_request(message.payload)

        if service_spec
          logger.info("Intelligence: Service specification generated: #{service_spec}")

          if !service_exists?(service_spec[:name])
            logger.info("Intelligence: Department #{service_spec[:name]} does not exist, recommending creation")

            # Forward to Operations subsystem for actual creation
            bus.emit VSM::Message.new(
              kind: :create_service,
              payload: { spec: service_spec },
              meta: message.meta
            )

            # Respond with analysis result
            bus.emit VSM::Message.new(
              kind: :assistant,
              payload: "Analysis complete: Creating #{service_spec[:name]} department",
              meta: message.meta
            )
          else
            logger.info("Intelligence: Department #{service_spec[:name]} already exists")
            bus.emit VSM::Message.new(
              kind: :assistant,
              payload: "Department #{service_spec[:name]} already exists",
              meta: message.meta
            )
          end
        else
          logger.warn("Intelligence: Failed to analyze service request: #{message.payload}")
          bus.emit VSM::Message.new(
            kind: :assistant,
            payload: "Could not understand service request - insufficient information for analysis",
            meta: message.meta
          )
        end
        true
      else
        logger.debug("Intelligence: Message does not require new service: #{message.payload}")
        false
      end
    end

    # Environmental scanning - assess what services are needed
    def scan_environment
      logger.info("Intelligence: Performing environmental scan")
      
      current_departments = @council.discover_departments
      service_gaps = identify_service_gaps(current_departments)
      
      logger.info("Intelligence: Identified #{service_gaps.size} potential service gaps")
      service_gaps.each { |gap| logger.debug("Intelligence: Service gap: #{gap}") }
      
      service_gaps
    end

    # Analyze service request using AI and fallback heuristics
    def analyze_service_request(request)
      logger.info("Intelligence: Analyzing service request: #{request}")
      
      # Check cache first
      cache_key = Digest::SHA256.hexdigest(request.to_s)
      if @analysis_cache[cache_key]
        logger.debug("Intelligence: Using cached analysis")
        return @analysis_cache[cache_key]
      end

      unless @ai_available
        logger.info("Intelligence: AI not available, using heuristic analysis")
        result = heuristic_analysis(request)
        @analysis_cache[cache_key] = result if result
        return result
      end

      existing_departments = @council.discover_departments
      logger.debug("Intelligence: Current departments for context: #{existing_departments.join(', ')}")

      prompt = build_analysis_prompt(request, existing_departments)

      begin
        logger.debug("Intelligence: Sending AI prompt for service analysis")
        response = @llm.ask(prompt)
        logger.debug("Intelligence: AI response received: #{response.content}")

        parsed_response = JSON.parse(response.content, symbolize_names: true)
        
        # Validate and enrich the AI response
        validated_spec = validate_and_enrich_spec(parsed_response, request)
        
        @analysis_cache[cache_key] = validated_spec
        logger.info("Intelligence: AI analysis successful: #{validated_spec}")
        validated_spec
      rescue => e
        logger.error("Intelligence: AI analysis failed: #{e.message}")
        logger.info("Intelligence: Falling back to heuristic analysis")
        result = heuristic_analysis(request)
        @analysis_cache[cache_key] = result if result
        result
      end
    end

    # Determine if a request indicates need for a new service
    def needs_new_service?(payload)
      service_keywords = ['need', 'missing', 'create', 'department', 'service', 'establish', 'build', 'require']
      emergency_keywords = ['emergency', 'urgent', 'critical', 'immediate']
      
      text = payload.to_s.downcase
      has_service_keywords = service_keywords.any? { |word| text.include?(word) }
      has_emergency_keywords = emergency_keywords.any? { |word| text.include?(word) }
      
      # Weight emergency requests higher
      score = 0
      score += 2 if has_service_keywords
      score += 3 if has_emergency_keywords
      score += 1 if text.length > 50  # Longer requests likely more detailed
      
      result = score >= 2
      logger.debug("Intelligence: Service need analysis - score: #{score}, result: #{result}")
      result
    end

    # Check if a service already exists
    def service_exists?(service_name)
      filename = "#{service_name}_department.rb"
      filepath = File.join(__dir__, '..', filename)
      exists = File.exist?(filepath)
      logger.debug("Intelligence: Service existence check - #{service_name}: #{exists}")
      exists
    end

    # Identify gaps in current city services
    def identify_service_gaps(current_departments)
      essential_services = %w[
        water_management utilities sanitation transportation
        parks_recreation library animal_control building_inspection
        environmental_health code_enforcement traffic_management
        parking_enforcement waste_management emergency_management
      ]
      
      existing_types = current_departments.map { |dept| dept.gsub('_department', '') }
      gaps = essential_services - existing_types
      
      logger.debug("Intelligence: Essential services: #{essential_services.size}")
      logger.debug("Intelligence: Existing types: #{existing_types.size}")
      logger.debug("Intelligence: Service gaps: #{gaps.size}")
      
      gaps
    end

    private

    def setup_ai
      begin
        RubyLLM.configure do |config|
          config.anthropic_api_key = ENV.fetch('ANTHROPIC_API_KEY', nil)
          config.openai_api_key = ENV.fetch('OPENAI_API_KEY', nil)
          config.log_file = "log/city_council_llm.log"
          config.log_level = :info
        end
        @llm = RubyLLM.chat
        @ai_available = true
        logger.info("Intelligence: AI model initialized successfully")
      rescue => e
        @ai_available = false
        logger.warn("Intelligence: AI not available: #{e.message}")
      end
    end

    def build_analysis_prompt(request, existing_departments)
      <<~PROMPT
        As a city governance intelligence analyst, analyze this service request:
        
        REQUEST: "#{request}"
        
        CURRENT DEPARTMENTS: #{existing_departments.join(', ')}
        
        Determine:
        1. What specific city department is needed?
        2. What are its primary responsibilities?
        3. Is this an emergency response department?
        4. What message types should it handle?
        5. Confidence level (0-100) in this analysis
        
        Respond in this exact JSON format:
        {
          "name": "department_name_in_snake_case",
          "description": "clear description of what it does",
          "responsibilities": ["responsibility1", "responsibility2"],
          "message_types": ["MessageType1", "MessageType2"],
          "emergency_response": true/false,
          "confidence": 85,
          "reasoning": "brief explanation of analysis"
        }
        
        Requirements:
        - Use snake_case for name (e.g., "traffic_management", "animal_control")
        - Be specific about responsibilities
        - Only suggest if confidence > 70
        - If confidence < 70, set name to "unknown"
      PROMPT
    end

    def validate_and_enrich_spec(ai_spec, original_request)
      # Validate required fields
      return nil unless ai_spec[:name] && ai_spec[:name] != "unknown"
      return nil unless ai_spec[:confidence] && ai_spec[:confidence] > 70
      
      # Enrich with additional intelligence
      enriched_spec = ai_spec.dup
      enriched_spec[:original_request] = original_request
      enriched_spec[:analysis_timestamp] = Time.now.iso8601
      enriched_spec[:priority] = determine_priority(enriched_spec)
      enriched_spec[:estimated_resources] = estimate_resources(enriched_spec)
      
      enriched_spec
    end

    def determine_priority(spec)
      if spec[:emergency_response]
        'high'
      elsif spec[:description] && spec[:description].downcase.include?('urgent')
        'medium'
      else
        'normal'
      end
    end

    def estimate_resources(spec)
      base_resources = {
        cpu: 'low',
        memory: 'low', 
        storage: 'minimal',
        network: 'low'
      }
      
      if spec[:emergency_response]
        base_resources[:cpu] = 'medium'
        base_resources[:network] = 'medium'
      end
      
      base_resources
    end

    def heuristic_analysis(request)
      logger.info("Intelligence: Using heuristic analysis for request: #{request}")

      # Simple keyword-based analysis
      words = request.downcase.split
      logger.debug("Intelligence: Request keywords: #{words.join(', ')}")

      department_patterns = {
        'traffic' => {
          name: 'traffic_management',
          description: 'Manages traffic flow, signals, and road conditions',
          emergency_response: true
        },
        'parking' => {
          name: 'parking_enforcement', 
          description: 'Enforces parking regulations and manages violations',
          emergency_response: false
        },
        'sanitation' => {
          name: 'sanitation',
          description: 'Manages waste collection and public cleanliness',
          emergency_response: false
        },
        'water' => {
          name: 'water_management',
          description: 'Manages water supply, quality, and distribution',
          emergency_response: true
        },
        'utilities' => {
          name: 'utilities',
          description: 'Manages public utilities and infrastructure',
          emergency_response: true
        },
        'parks' => {
          name: 'parks_recreation',
          description: 'Manages parks, recreational facilities, and programs',
          emergency_response: false
        },
        'animal' => {
          name: 'animal_control',
          description: 'Manages animal control and public safety',
          emergency_response: true
        },
        'building' => {
          name: 'building_inspection',
          description: 'Inspects buildings for safety and code compliance',
          emergency_response: false
        }
      }

      # Find best match
      best_match = nil
      best_score = 0
      
      department_patterns.each do |keyword, pattern|
        score = words.count { |word| word.include?(keyword) }
        if score > best_score
          best_score = score
          best_match = pattern
        end
      end

      if best_match
        result = {
          name: best_match[:name],
          description: best_match[:description],
          responsibilities: ["Handle #{best_match[:name].gsub('_', ' ')} requests", "Monitor #{best_match[:name].gsub('_', ' ')} status"],
          message_types: ["#{best_match[:name].capitalize}RequestMessage"],
          emergency_response: best_match[:emergency_response],
          confidence: [best_score * 20, 100].min,  # Cap at 100
          reasoning: "Heuristic analysis matched keyword pattern",
          analysis_method: 'heuristic'
        }
        
        logger.info("Intelligence: Heuristic analysis result: #{result}")
        result
      else
        logger.warn("Intelligence: Heuristic analysis could not identify department type")
        nil
      end
    end
  end
end