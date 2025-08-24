#!/usr/bin/env ruby
# city_council/operations.rb
# CityCouncil Operations Component - VSM Operations Subsystem

require_relative '../smart_message/lib/smart_message'
require_relative '../vsm/lib/vsm'
require 'json'
require 'fileutils'
require 'securerandom'

require_relative '../common/logger'

# Load all existing message types
Dir[File.join(__dir__, '..', 'messages', '*.rb')].each { |file| require file }

module CityCouncil
  # CityCouncil VSM Operations Component
  # Handles the actual creation, management, and lifecycle of city departments
  class Operations < VSM::Operations
    include Common::Logger

    def initialize(council)
      @council = council
      @service_name = 'city_council-operations'
      @active_operations = {}
      @department_templates = {}
    end

    def handle(message, bus:, **)
      case message.kind
      when :create_service
        handle_create_service(message, bus)
      when :manage_department
        handle_manage_department(message, bus)
      else
        false
      end
    end

    # Main service creation operation
    def create_city_service(spec)
      logger.info("Operations: Starting creation of city service: #{spec[:name]}")
      logger.debug("Service specification: #{spec}")

      operation_id = SecureRandom.uuid
      @active_operations[operation_id] = {
        spec: spec,
        status: 'creating',
        started_at: Time.now
      }

      begin
        # Create department from generic template
        logger.info("Operations: Creating department from generic template: #{spec[:name]}")
        result = create_department_from_template(spec)
        
        if result
          department_file = result[:department_file]
          config_file = result[:config_file]
          
          logger.info("Operations: Template-based department created successfully")
          logger.info("Operations: Department file: #{department_file}")
          logger.info("Operations: Configuration file: #{config_file}")
          
          @active_operations[operation_id][:status] = 'launching'
          
          # Announce department creation
          logger.info("Operations: Publishing department creation announcement")
          announce_department_created(spec, department_file)

          # Launch the new department
          logger.info("Operations: Launching department process: #{department_file}")
          department_pid = launch_department(department_file)

          if department_pid
            # Announce successful launch
            logger.info("Operations: Department launch successful, publishing launch announcement")
            announce_department_launched(spec, department_file, department_pid)
            logger.info("Operations: Successfully launched #{department_file} with PID #{department_pid}")
            
            @active_operations[operation_id][:status] = 'completed'
            @active_operations[operation_id][:pid] = department_pid
          else
            logger.error("Operations: Department launch failed for #{department_file}")
            announce_department_failed(spec, department_file, "Failed to launch process")
            logger.error("Operations: Failed to launch #{department_file}")
            @active_operations[operation_id][:status] = 'failed'
          end

          # Register the new service
          logger.info("Operations: Registering new department with CityCouncil")
          @council.register_new_department(spec[:name], department_pid)

          logger.info("Operations: City service creation completed: #{spec[:name]}")
          @active_operations[operation_id][:completed_at] = Time.now
          true
        else
          logger.error("Operations: Failed to create department from template")
          announce_department_failed(spec, "#{spec[:name]}_department.rb", "Template creation failed")
          @active_operations[operation_id][:status] = 'failed'
          false
        end
      rescue => e
        logger.error("Operations: Failed to create service #{spec ? spec[:name] : 'unknown'}: #{e.message}")
        logger.error("Operations: Exception backtrace: #{e.backtrace.join("\n")}")
        announce_department_failed(spec, "#{spec[:name]}_department.rb", e.message)
        @active_operations[operation_id][:status] = 'failed'
        @active_operations[operation_id][:error] = e.message
        false
      end
    end

    def create_department_from_template(spec)
      logger.info("Operations: 📝 Creating #{spec[:name]} from generic template")
      
      template_path = File.join(__dir__, '..', 'generic_template.rb')
      department_file = File.join(__dir__, '..', "#{spec[:name]}_department.rb")
      config_file = File.join(__dir__, '..', "#{spec[:name]}_department.yml")
      
      # Check if template exists
      unless File.exist?(template_path)
        logger.error("Operations: ❌ Generic template not found: #{template_path}")
        return nil
      end
      
      logger.info("Operations: 📁 Copying template: #{template_path} → #{department_file}")
      FileUtils.cp(template_path, department_file)
      
      # Generate YAML configuration
      logger.info("Operations: ⚙️ Generating configuration: #{config_file}")
      config = generate_department_config(spec)
      File.write(config_file, config.to_yaml)
      
      # Make executable
      FileUtils.chmod(0755, department_file)
      
      logger.info("Operations: ✅ Department #{spec[:name]} created successfully using template approach")
      logger.info("Operations: 📋 Template uses common/logger mixin for consistent logging")
      
      {
        department_file: File.basename(department_file),
        config_file: File.basename(config_file),
        template_used: File.basename(template_path)
      }
    end

    def generate_department_config(spec)
      {
        'department' => {
          'name' => "#{spec[:name]}_department",
          'display_name' => spec[:display_name] || spec[:name].split('_').map(&:capitalize).join(' '),
          'description' => spec[:description],
          'invariants' => [
            "serve citizens efficiently",
            "respond to emergencies promptly", 
            "maintain operational readiness"
          ]
        },
        'capabilities' => spec[:responsibilities] || [],
        'message_types' => {
          'subscribes_to' => determine_subscription_messages(spec),
          'publishes' => spec[:message_types] || []
        },
        'routing_rules' => generate_routing_rules(spec),
        'message_actions' => generate_message_actions(spec),
        'action_configs' => generate_action_configs(spec),
        'ai_analysis' => {
          'enabled' => false,  # Can be enabled per department type
          'context' => "You are the #{spec[:name]} department. Handle #{spec[:description].downcase}."
        },
        'logging' => {
          'level' => 'info',
          'statistics_interval' => 300
        }
      }
    end

    def determine_subscription_messages(spec)
      messages = ['health_check_message']
      
      # Add emergency message if it handles emergencies
      if spec[:description] && spec[:description].downcase.include?('emergency')
        messages << 'emergency_911_message'
      end
      
      # Add specific message types based on department type
      department_type = spec[:name].split('_').first
      case department_type
      when 'water', 'utilities'
        messages << 'emergency_911_message'
      when 'animal'
        messages << 'emergency_911_message'
      when 'transportation'
        messages << 'emergency_911_message'
      when 'building'
        messages << 'emergency_911_message'
      when 'environmental'
        messages << 'emergency_911_message'
      when 'parks'
        messages << 'emergency_911_message'
      end
      
      messages.uniq
    end

    def generate_routing_rules(spec)
      rules = {}
      
      # Default emergency_911_message routing
      if spec[:description]
        keywords = extract_keywords_from_description(spec[:description])
        rules['emergency_911_message'] = [{
          'condition' => "message contains relevant keywords",
          'keywords' => keywords,
          'priority' => 'high'
        }]
      end
      
      # Health check routing
      rules['health_check_message'] = [{
        'condition' => 'always',
        'priority' => 'normal'
      }]
      
      rules
    end

    def generate_message_actions(spec)
      actions = {}
      
      # Map message types to actions
      actions['emergency_911_message'] = 'handle_emergency'
      actions['health_check_message'] = 'respond_health_check'
      
      # Add specific actions based on message types
      (spec[:message_types] || []).each do |msg_type|
        action_name = "handle_#{msg_type.gsub('_message', '').gsub('_', '_')}"
        actions[msg_type] = action_name
      end
      
      actions
    end

    def generate_action_configs(spec)
      configs = {}
      
      # Emergency handling configuration
      configs['handle_emergency'] = {
        'response_template' => "🚨 #{spec[:name].upcase}: Responding to {{emergency_type}} at {{location}}",
        'additional_actions' => ['log_emergency', 'notify_dispatch'],
        'publish_response' => true
      }
      
      # Health check configuration  
      configs['respond_health_check'] = {
        'response_template' => "💗 #{spec[:name]} is operational",
        'publish_response' => true
      }
      
      configs
    end

    def extract_keywords_from_description(description)
      # Extract relevant keywords for message routing
      words = description.downcase.split(/\W+/)
      keywords = words.select { |word| word.length > 3 }
      keywords.take(5) # Limit to top 5 keywords
    end

    def launch_department(department_file)
      logger.info("Operations: Attempting to launch department: #{department_file}")

      begin
        # Launch the department as a separate process
        command = "ruby #{department_file}"
        logger.debug("Operations: Executing command: #{command}")
        pid = spawn(command, chdir: File.join(__dir__, '..'))
        logger.debug("Operations: Process spawned with PID: #{pid}")

        Process.detach(pid) # Detach so we don't wait for it
        logger.debug("Operations: Process detached from parent")

        # Give it a moment to start up
        logger.debug("Operations: Waiting 2 seconds for process to initialize")
        sleep(2)

        # Check if process is still running
        begin
          Process.kill(0, pid) # Send signal 0 to check if process exists
          logger.info("Operations: Department #{department_file} launched successfully with PID #{pid}")
          return pid
        rescue Errno::ESRCH
          logger.error("Operations: Department #{department_file} failed to start properly - process not found")
          return nil
        end
      rescue => e
        logger.error("Operations: Failed to launch #{department_file}: #{e.message}")
        logger.error("Operations: Launch exception backtrace: #{e.backtrace.join("\n")}")
        return nil
      end
    end

    def announce_department_created(spec, department_file)
      logger.info("Operations: Creating department creation announcement for: #{spec[:name]}_department")

      announcement = Messages::DepartmentAnnouncementMessage.new(
        department_name: "#{spec[:name]}_department",
        department_file: department_file,
        status: 'created',
        description: spec[:description],
        capabilities: spec[:responsibilities] || [],
        message_types: spec[:message_types] || [],
        reason: "Generated due to emergency service request"
      )
      announcement._sm_header.from = @service_name

      logger.debug("Operations: Publishing department creation announcement: #{announcement.inspect}")
      announcement.publish
      logger.info("Operations: Successfully announced department creation: #{spec[:name]}_department")
    end

    def announce_department_launched(spec, department_file, pid)
      logger.info("Operations: Creating department launch announcement for: #{spec[:name]}_department (PID: #{pid})")

      announcement = Messages::DepartmentAnnouncementMessage.new(
        department_name: "#{spec[:name]}_department",
        department_file: department_file,
        status: 'launched',
        description: spec[:description],
        capabilities: spec[:responsibilities] || [],
        message_types: spec[:message_types] || [],
        process_id: pid,
        reason: "Generated due to emergency service request"
      )
      announcement._sm_header.from = @service_name

      logger.debug("Operations: Publishing department launch announcement: #{announcement.inspect}")
      announcement.publish
      logger.info("Operations: Successfully announced department launch: #{spec[:name]}_department (PID: #{pid})")

      puts "🏛️ NEW DEPARTMENT LAUNCHED: #{spec[:name]}_department (PID: #{pid})"
    end

    def announce_department_failed(spec, department_file, error_msg)
      dept_name = spec ? "#{spec[:name]}_department" : "unknown"
      logger.error("Operations: Creating department failure announcement for: #{dept_name}")
      logger.error("Operations: Failure reason: #{error_msg}")

      announcement = Messages::DepartmentAnnouncementMessage.new(
        department_name: dept_name,
        department_file: department_file,
        status: 'failed',
        description: error_msg,
        reason: "Generation or launch failed"
      )
      announcement._sm_header.from = @service_name

      logger.debug("Operations: Publishing department failure announcement: #{announcement.inspect}")
      announcement.publish
      logger.error("Operations: Successfully announced department failure: #{department_file} - #{error_msg}")
    end

    # Operations monitoring and management
    def get_active_operations
      @active_operations
    end

    def get_operation_status(operation_id)
      @active_operations[operation_id]
    end

    def cleanup_completed_operations
      @active_operations.reject! { |id, op| op[:status] == 'completed' && (Time.now - op[:completed_at]) > 3600 }
    end

    private

    def handle_create_service(message, bus)
      logger.info("Operations: Received create_service request: #{message.payload}")
      
      spec = message.payload[:spec]
      if spec
        success = create_city_service(spec)
        
        bus.emit VSM::Message.new(
          kind: :operation_result,
          payload: { 
            operation: 'create_service',
            success: success,
            service_name: spec[:name]
          },
          meta: message.meta
        )
        true
      else
        logger.error("Operations: Invalid create_service message - missing spec")
        false
      end
    end

    def handle_manage_department(message, bus)
      logger.info("Operations: Received manage_department request: #{message.payload}")
      # Future: Add department lifecycle management operations
      false
    end
  end
end