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
      puts "🏛️ 🧠 Intelligence: Received #{message.kind} message"
      puts "🏛️ 📝 Content: #{message.payload.to_s.slice(0, 100)}#{message.payload.to_s.length > 100 ? '...' : ''}"

      # Check if this is a request for a new service
      needs_service = needs_new_service?(message.payload)
      puts "🏛️ 🔍 Intelligence: Service needed analysis result: #{needs_service}"
      
      if needs_service
        logger.info("Intelligence: Analyzing request for new service: #{message.payload}")
        puts "🏛️ 🎯 Intelligence: Starting service analysis..."

        # Extract service requirements using intelligence analysis
        service_spec = analyze_service_request(message.payload)
        puts "🏛️ 📋 Intelligence: Service spec generated: #{service_spec ? service_spec[:name] : 'FAILED'}"

        if service_spec
          logger.info("Intelligence: Service specification generated: #{service_spec}")

          if !service_exists?(service_spec[:name])
            logger.info("Intelligence: Department #{service_spec[:name]} does not exist, recommending creation")
            puts "🏛️ ✨ Intelligence: Department #{service_spec[:name]} doesn't exist - emitting create_service"

            # Forward to Operations subsystem for actual creation
            create_service_msg = VSM::Message.new(
              kind: :create_service,
              payload: { spec: service_spec },
              meta: message.meta
            )
            puts "🏛️ 📤 Intelligence: About to emit create_service message: #{create_service_msg.kind}"
            puts "🏛️ 📄 Service spec: #{service_spec[:name]} - #{service_spec[:description]}"
            puts "🏛️ 🚌 Bus subscribers: #{bus.instance_variable_get(:@subs).size}"
            puts "🏛️ 🚌 Bus object ID: #{bus.object_id}"
            bus.emit create_service_msg
            puts "🏛️ ✅ Intelligence: create_service message emitted to VSM bus"
            sleep(0.1) # Give async fiber a moment to process

            # Respond with analysis result
            bus.emit VSM::Message.new(
              kind: :assistant,
              payload: "Analysis complete: Creating #{service_spec[:name]} department",
              meta: message.meta
            )
          else
            logger.info("Intelligence: Department #{service_spec[:name]} already exists")
            puts "🏛️ ✅ Intelligence: Department #{service_spec[:name]} already exists"
            bus.emit VSM::Message.new(
              kind: :assistant,
              payload: "Department #{service_spec[:name]} already exists",
              meta: message.meta
            )
          end
        else
          logger.warn("Intelligence: Failed to analyze service request: #{message.payload}")
          puts "🏛️ ❌ Intelligence: Failed to analyze service request"
          bus.emit VSM::Message.new(
            kind: :assistant,
            payload: "Could not understand service request - insufficient information for analysis",
            meta: message.meta
          )
        end
        true
      else
        logger.debug("Intelligence: Message does not require new service: #{message.payload}")
        puts "🏛️ ❓ Intelligence: Message does not require new service"
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
      puts "🏛️ 🧮 Intelligence: Starting analysis of service request..."
      
      # Check cache first
      cache_key = Digest::SHA256.hexdigest(request.to_s)
      if @analysis_cache[cache_key]
        logger.debug("Intelligence: Using cached analysis")
        puts "🏛️ 💾 Intelligence: Using cached analysis result"
        return @analysis_cache[cache_key]
      end

      puts "🏛️ 🤖 Intelligence: AI available: #{@ai_available}"
      unless @ai_available
        logger.info("Intelligence: AI not available, using heuristic analysis")
        puts "🏛️ 🧮 Intelligence: AI not available, falling back to heuristic analysis"
        result = heuristic_analysis(request)
        @analysis_cache[cache_key] = result if result
        puts "🏛️ 📊 Intelligence: Heuristic analysis result: #{result ? result[:name] : 'FAILED'}"
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
      puts "🏛️ 🔍 Intelligence: Analyzing text: '#{text.slice(0, 80)}#{text.length > 80 ? '...' : ''}'"
      
      has_service_keywords = service_keywords.any? { |word| text.include?(word) }
      has_emergency_keywords = emergency_keywords.any? { |word| text.include?(word) }
      
      puts "🏛️ 🔍 Service keywords found: #{has_service_keywords} (#{service_keywords.select { |word| text.include?(word) }.join(', ')})"
      puts "🏛️ 🔍 Emergency keywords found: #{has_emergency_keywords} (#{emergency_keywords.select { |word| text.include?(word) }.join(', ')})"
      
      # Weight emergency requests higher
      score = 0
      score += 2 if has_service_keywords
      score += 3 if has_emergency_keywords
      score += 1 if text.length > 50  # Longer requests likely more detailed
      
      puts "🏛️ 🔍 Scoring: service_keywords(+2)=#{has_service_keywords ? 2 : 0}, emergency_keywords(+3)=#{has_emergency_keywords ? 3 : 0}, length(+1)=#{text.length > 50 ? 1 : 0}"
      puts "🏛️ 🔍 Total score: #{score}, threshold: 2"
      
      result = score >= 2
      puts "🏛️ 🔍 Final result: #{result}"
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
      puts "🏛️ 🧮 Intelligence: Running heuristic analysis on: '#{request.to_s.slice(0, 80)}#{request.to_s.length > 80 ? '...' : ''}'"

      # Simple keyword-based analysis
      words = request.downcase.split
      logger.debug("Intelligence: Request keywords: #{words.join(', ')}")
      puts "🏛️ 🔍 Keywords extracted: #{words.join(', ')}"

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
        },
        'public' => {
          name: 'public_works',
          description: 'Manages public infrastructure, roads, and facilities maintenance',
          emergency_response: true
        },
        'works' => {
          name: 'public_works',
          description: 'Manages public infrastructure, roads, and facilities maintenance',
          emergency_response: true
        },
        'environmental' => {
          name: 'environmental_services',
          description: 'Handles environmental protection and hazardous material cleanup',
          emergency_response: true
        }
      }

      # Find best match
      best_match = nil
      best_score = 0
      matched_keyword = nil
      
      puts "🏛️ 🎯 Matching against department patterns..."
      department_patterns.each do |keyword, pattern|
        score = words.count { |word| word.include?(keyword) }
        puts "🏛️ 🔍 Checking '#{keyword}' pattern: score=#{score} (matches: #{words.select { |word| word.include?(keyword) }.join(', ')})"
        if score > best_score
          best_score = score
          best_match = pattern
          matched_keyword = keyword
        end
      end
      
      puts "🏛️ 🎯 Best match: '#{matched_keyword}' with score #{best_score}"

      if best_match && best_score > 0
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
        
        puts "🏛️ ✅ Intelligence: Heuristic analysis successful: #{result[:name]}"
        logger.info("Intelligence: Heuristic analysis result: #{result}")
        result
      else
        puts "🏛️ ❌ Intelligence: Heuristic analysis found no matching patterns"
        logger.warn("Intelligence: Heuristic analysis could not identify department type")
        nil
      end
    end
  end
end