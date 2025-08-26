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

    def initialize(council:, **)
      @council = council
      @service_name = 'city_council-operations'
      @active_operations = {}
      @department_templates = {}
      @department_health = {} # Track health of launched departments
      @health_check_interval = 30 # Check health every 30 seconds
      @last_health_check = Time.now
      logger.info("Operations: Initialized with service_name: #{@service_name}")

      # Start monitoring thread
      start_department_monitoring
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

      puts "🏛️ ⚙️ Operations: Starting creation of new city service: #{spec[:name]}"
      puts "🏛️ 📝 Service description: #{spec[:description]}"

      operation_id = SecureRandom.uuid
      @active_operations[operation_id] = {
        spec: spec,
        status: 'creating',
        started_at: Time.now
      }

      begin
        # Create department from generic template
        logger.info("Operations: Creating department from generic template: #{spec[:name]}")
        puts "🏛️ 🏗️ Operations: Creating department from template..."
        result = create_department_from_template(spec)

        if result
          department_file = result[:department_file]
          config_file = result[:config_file]

          logger.info("Operations: Template-based department created successfully")
          logger.info("Operations: Department file: #{department_file}")
          logger.info("Operations: Configuration file: #{config_file}")

          puts "🏛️ ✅ Operations: Department files created successfully"
          puts "🏛️ 📁 Department file: #{department_file}"
          puts "🏛️ ⚙️ Config file: #{config_file}"

          @active_operations[operation_id][:status] = 'launching'

          # Announce department creation
          logger.info("Operations: Publishing department creation announcement")
          puts "🏛️ 📢 Operations: Announcing department creation..."
          announce_department_created(spec, result[:department_file])

          # Launch the new department using the actual created filename
          actual_department_file = result[:department_file] # This is the basename of the actual file created
          logger.info("Operations: Launching department process: #{actual_department_file}")
          puts "🏛️ 🚀 Operations: Launching department process: #{actual_department_file}"
          department_pid = launch_department(actual_department_file)

          if department_pid
            # Announce successful launch
            logger.info("Operations: Department launch successful, publishing launch announcement")
            puts "🏛️ 🎉 Operations: Department launched successfully with PID #{department_pid}"
            announce_department_launched(spec, actual_department_file, department_pid)
            logger.info("Operations: Successfully launched #{actual_department_file} with PID #{department_pid}")

            # Register department for health monitoring
            register_department_for_monitoring(spec[:name], department_pid, actual_department_file)

            @active_operations[operation_id][:status] = 'completed'
            @active_operations[operation_id][:pid] = department_pid
          else
            logger.error("Operations: Department launch failed for #{actual_department_file}")
            puts "🏛️ ❌ Operations: Department launch failed for #{actual_department_file}"
            announce_department_failed(spec, actual_department_file, "Failed to launch process")
            logger.error("Operations: Failed to launch #{department_file}")
            @active_operations[operation_id][:status] = 'failed'
          end

          # Register the new service
          logger.info("Operations: Registering new department with CityCouncil")
          puts "🏛️ 📋 Operations: Registering new department with CityCouncil"
          @council.register_new_department(spec[:name], department_pid)

          logger.info("Operations: City service creation completed: #{spec[:name]}")
          puts "🏛️ 🏁 Operations: City service creation completed: #{spec[:name]}"
          @active_operations[operation_id][:completed_at] = Time.now
          true
        else
          logger.error("Operations: Failed to create department from template")
          puts "🏛️ ❌ Operations: Failed to create department from template"
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

      puts "🏛️ 📝 Creating #{spec[:name]} from generic template..."

      # Ensure the department name ends with _department (but don't duplicate it)
      dept_name = spec[:name].end_with?('_department') ? spec[:name] : "#{spec[:name]}_department"

      template_path = File.join(__dir__, '..', 'generic_department.rb')
      config_file = File.join(__dir__, '..', "#{dept_name}.yml")

      puts "🏛️ 📁 Template program: #{template_path}"
      puts "🏛️ ⚙️ Target config: #{config_file}"

      # Check if template exists
      unless File.exist?(template_path)
        logger.error("Operations: ❌ Generic department template not found: #{template_path}")
        puts "🏛️ ❌ Generic department template not found: #{template_path}"
        return nil
      end

      # Generate YAML configuration (no need to copy the template file anymore)
      logger.info("Operations: ⚙️ Generating configuration: #{config_file}")
      puts "🏛️ ⚙️ Generating YAML configuration..."
      config = generate_department_config(spec.merge(name: dept_name))
      File.write(config_file, config.to_yaml)

      logger.info("Operations: ✅ Department #{spec[:name]} created successfully using config approach")
      logger.info("Operations: 📋 Department will run via: ruby generic_department.rb #{dept_name}")
      puts "🏛️ ✅ Department #{spec[:name]} config created - can be run with: ruby generic_department.rb #{dept_name}"

      {
        config_file: File.basename(config_file),
        template_used: File.basename(template_path),
        run_command: "ruby #{File.basename(template_path)} #{dept_name}"
      }
    end

    def generate_department_config(spec)
      {
        'department' => {
          'name' => spec[:name],
          'display_name' => spec[:display_name] || spec[:name].gsub('_department', '').split('_').map(&:capitalize).join(' '),
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
      puts "🏛️ 🚀 Attempting to launch department: #{department_file}"

      begin
        # Launch the department as a separate process
        command = "ruby #{department_file}"
        logger.debug("Operations: Executing command: #{command}")
        puts "🏛️ 💻 Executing command: #{command}"
        pid = spawn(command, chdir: File.join(__dir__, '..'))
        logger.debug("Operations: Process spawned with PID: #{pid}")
        puts "🏛️ 🆔 Process spawned with PID: #{pid}"

        Process.detach(pid) # Detach so we don't wait for it
        logger.debug("Operations: Process detached from parent")
        puts "🏛️ 🔗 Process detached from parent"

        # Give it a moment to start up
        logger.debug("Operations: Waiting 2 seconds for process to initialize")
        puts "🏛️ ⏱️ Waiting 2 seconds for process to initialize..."
        sleep(2)

        # Check if process is still running
        begin
          Process.kill(0, pid) # Send signal 0 to check if process exists
          logger.info("Operations: Department #{department_file} launched successfully with PID #{pid}")
          puts "🏛️ ✅ Department #{department_file} launched successfully with PID #{pid}"
          return pid
        rescue Errno::ESRCH
          logger.error("Operations: Department #{department_file} failed to start properly - process not found")
          puts "🏛️ ❌ Department #{department_file} failed to start properly - process not found"
          return nil
        end
      rescue => e
        logger.error("Operations: Failed to launch #{department_file}: #{e.message}")
        logger.error("Operations: Launch exception backtrace: #{e.backtrace.join("\n")}")
        puts "🏛️ ❌ Failed to launch #{department_file}: #{e.message}"
        return nil
      end
    end

    def announce_department_created(spec, department_file)
      Messages::DepartmentAnnouncementMessage.from(@service_name)

      dept_name = spec[:name].end_with?('_department') ? spec[:name] : "#{spec[:name]}_department"
      logger.info("Operations: Creating department creation announcement for: #{dept_name}")
      logger.info("Operations: Current @service_name value: #{@service_name.inspect}")

      announcement = Messages::DepartmentAnnouncementMessage.new(
        department_name: dept_name,
        department_file: department_file,
        status: 'created',
        description: spec[:description],
        capabilities: spec[:responsibilities] || [],
        message_types: spec[:message_types] || [],
        reason: "Generated due to emergency service request"
      )
      announcement.from(@service_name)  # Use the proper method to set from field

      logger.debug("Operations: Service name: #{@service_name}")
      logger.debug("Operations: Announcement from field: #{announcement._sm_header.from}")
      logger.debug("Operations: Publishing department creation announcement: #{announcement.inspect}")

      begin
        announcement.publish
      rescue => e
        logger.error("Operations: Failed to publish announcement: #{e.message}")
        logger.error("Operations: Announcement details: #{announcement.inspect}")
      end
      logger.info("Operations: Successfully announced department creation: #{dept_name}")
    end

    def announce_department_launched(spec, department_file, pid)
      dept_name = spec[:name].end_with?('_department') ? spec[:name] : "#{spec[:name]}_department"
      logger.info("Operations: Creating department launch announcement for: #{dept_name} (PID: #{pid})")

      announcement = Messages::DepartmentAnnouncementMessage.new(
        department_name: dept_name,
        department_file: department_file,
        status: 'launched',
        description: spec[:description],
        capabilities: spec[:responsibilities] || [],
        message_types: spec[:message_types] || [],
        process_id: pid,
        reason: "Generated due to emergency service request"
      )
      announcement.from(@service_name)  # Use the proper method to set from field

      logger.debug("Operations: Publishing department launch announcement: #{announcement.inspect}")

      begin
        announcement.publish
      rescue => e
        logger.error("Operations: Failed to publish launch announcement: #{e.message}")
        logger.error("Operations: Announcement details: #{announcement.inspect}")
      end
      logger.info("Operations: Successfully announced department launch: #{dept_name} (PID: #{pid})")

      puts "🏛️ NEW DEPARTMENT LAUNCHED: #{dept_name} (PID: #{pid})"
    end

    def announce_department_failed(spec, department_file, error_msg)
      if spec
        dept_name = spec[:name].end_with?('_department') ? spec[:name] : "#{spec[:name]}_department"
      else
        dept_name = "unknown"
      end
      logger.error("Operations: Creating department failure announcement for: #{dept_name}")
      logger.error("Operations: Failure reason: #{error_msg}")

      announcement = Messages::DepartmentAnnouncementMessage.new(
        department_name: dept_name,
        department_file: department_file,
        status: 'failed',
        description: error_msg,
        reason: "Generation or launch failed"
      )
      announcement.from(@service_name)  # Use the proper method to set from field

      logger.debug("Operations: Publishing department failure announcement: #{announcement.inspect}")

      begin
        announcement.publish
      rescue => e
        logger.error("Operations: Failed to publish failure announcement: #{e.message}")
        logger.error("Operations: Announcement details: #{announcement.inspect}")
      end
      logger.error("Operations: Successfully announced department failure: #{department_file} - #{error_msg}")
    end

    # Department Health Monitoring
    def start_department_monitoring
      logger.info("Operations: Starting department health monitoring thread")

      Thread.new do
        loop do
          begin
            sleep(10) # Check every 10 seconds
            monitor_department_health if Time.now - @last_health_check >= @health_check_interval
          rescue => e
            logger.error("Operations: Error in monitoring thread: #{e.message}")
            sleep(30) # Wait before retrying on error
          end
        end
      end
    end

    def monitor_department_health
      logger.debug("Operations: Performing health check on #{@department_health.size} departments")
      @last_health_check = Time.now

      @department_health.each do |dept_name, health_info|
        check_department_process_health(dept_name, health_info)
        send_health_check_to_department(dept_name, health_info) if health_info[:process_healthy]
      end

      cleanup_dead_departments
    end

    def check_department_process_health(dept_name, health_info)
      pid = health_info[:pid]

      begin
        # Check if process is still running
        Process.kill(0, pid)

        # Process exists, update health info
        unless health_info[:process_healthy]
          logger.info("Operations: Department #{dept_name} process recovered (PID: #{pid})")
          health_info[:process_healthy] = true
          health_info[:process_failures] = 0
        end

        health_info[:last_process_check] = Time.now

      rescue Errno::ESRCH
        # Process not found
        logger.warn("Operations: Department #{dept_name} process died (PID: #{pid})")
        health_info[:process_healthy] = false
        health_info[:process_failures] += 1
        health_info[:last_failure] = Time.now

        # Try to restart if failures are below threshold
        if health_info[:process_failures] <= 3
          logger.info("Operations: Attempting to restart #{dept_name} (failure #{health_info[:process_failures]}/3)")
          restart_department(dept_name, health_info)
        else
          logger.error("Operations: Department #{dept_name} has failed too many times, marking as permanently failed")
          health_info[:status] = 'permanently_failed'
        end

      rescue => e
        logger.error("Operations: Error checking process health for #{dept_name}: #{e.message}")
      end
    end

    def send_health_check_to_department(dept_name, health_info)
      return unless health_info[:process_healthy]

      begin
        # Create and send health check message
        if defined?(Messages::HealthCheckMessage)
          Messages::HealthCheckMessage.from(@service_name)
          health_check = Messages::HealthCheckMessage.new
          health_check.from(@service_name)
          health_check._sm_header.to = dept_name

          # Set up response timeout
          health_info[:last_health_request] = Time.now
          health_info[:awaiting_response] = true

          logger.debug("Operations: Sending health check to #{dept_name}")
          health_check.publish

          # Schedule response timeout check
          Thread.new do
            sleep(10) # 10 second timeout for health response
            if health_info[:awaiting_response] && (Time.now - health_info[:last_health_request]) > 10
              logger.warn("Operations: Department #{dept_name} failed to respond to health check")
              health_info[:health_check_failures] += 1
              health_info[:awaiting_response] = false
              health_info[:responsive] = false
            end
          end
        end
      rescue => e
        logger.error("Operations: Failed to send health check to #{dept_name}: #{e.message}")
      end
    end

    def restart_department(dept_name, health_info)
      logger.info("Operations: Restarting department #{dept_name}")

      begin
        # Try to launch the department again
        new_pid = launch_department(health_info[:department_file])

        if new_pid
          logger.info("Operations: Successfully restarted #{dept_name} with new PID #{new_pid}")
          health_info[:pid] = new_pid
          health_info[:process_healthy] = true
          health_info[:last_restart] = Time.now
          health_info[:restart_count] += 1

          # Register the new PID with council
          @council.update_department_pid(dept_name, new_pid)

          # Announce the restart
          puts "🏛️ ♻️ DEPARTMENT RESTARTED: #{dept_name} (new PID: #{new_pid})"
        else
          logger.error("Operations: Failed to restart #{dept_name}")
          health_info[:process_failures] += 1
        end
      rescue => e
        logger.error("Operations: Error restarting #{dept_name}: #{e.message}")
        health_info[:process_failures] += 1
      end
    end

    def cleanup_dead_departments
      @department_health.reject! do |dept_name, health_info|
        if health_info[:status] == 'permanently_failed'
          logger.info("Operations: Removing permanently failed department #{dept_name} from monitoring")
          true
        else
          false
        end
      end
    end

    def register_department_for_monitoring(dept_name, pid, department_file)
      logger.info("Operations: Registering #{dept_name} for health monitoring (PID: #{pid})")

      @department_health[dept_name] = {
        pid: pid,
        department_file: department_file,
        process_healthy: true,
        responsive: true,
        process_failures: 0,
        health_check_failures: 0,
        restart_count: 0,
        status: 'running',
        created_at: Time.now,
        last_process_check: Time.now,
        last_health_request: nil,
        last_failure: nil,
        last_restart: nil,
        awaiting_response: false
      }

      puts "🏛️ 📊 Monitoring started for #{dept_name} (PID: #{pid})"
    end

    def handle_health_response(dept_name, response)
      health_info = @department_health[dept_name]
      return unless health_info && health_info[:awaiting_response]

      logger.debug("Operations: Received health response from #{dept_name}")
      health_info[:awaiting_response] = false
      health_info[:responsive] = true
      health_info[:health_check_failures] = 0
      health_info[:last_health_response] = Time.now
    end

    def get_department_health_status
      @department_health
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
