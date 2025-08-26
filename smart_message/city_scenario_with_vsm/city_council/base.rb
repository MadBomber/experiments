#!/usr/bin/env ruby
# city_council/base.rb
#

require 'async'
require_relative '../common/status_line'

# Main CityCouncil Class
module CityCouncil
  class Base
    # include Common::HealthMonitor
    include Common::Logger
    include Common::StatusLine

    attr_reader :capsule, :existing_departments

    def initialize
      @service_name = "city_council"
      @status = "healthy"
      @start_time = Time.now
      @existing_departments = discover_departments
      @department_processes = {} # Track launched department PIDs

      setup_signal_handlers
      # setup_health_monitor
      setup_vsm_capsule
      setup_messaging

      logger.info("CityCouncil initialized with #{@existing_departments.size} existing departments")
    end

    def discover_departments
      logger.debug("Discovering existing departments in current directory")

      # Discover Ruby-based departments
      ruby_departments = Dir.glob("*_department.rb").map do |file|
        File.basename(file, ".rb")
      end

      # Discover YAML-configured departments
      yaml_departments = Dir.glob("*_department.yml").map do |file|
        File.basename(file, ".yml")
      end

      # Combine both types
      departments = (ruby_departments + yaml_departments).sort.uniq

      logger.info("Discovered #{departments.size} existing departments:")
      logger.info("  Ruby-based: #{ruby_departments.size} (#{ruby_departments.join(", ")})")
      logger.info("  YAML-configured: #{yaml_departments.size} (#{yaml_departments.join(", ")})")
      logger.info("  Total unique: #{departments.join(", ")}")

      departments
    end

    def setup_vsm_capsule
      logger.info("Setting up VSM capsule for CityCouncil")

      # Capture reference to CityCouncil instance before entering DSL block
      council_instance = self

      @capsule = VSM::DSL.define(:city_council) do
        identity klass: VSM::Identity,
                 args: {
                   identity: "city_council",
                   invariants: ["must serve citizens", "create needed services", "maintain city operations"],
                 }

        governance klass: CityCouncil::Governance
        coordination klass: VSM::Coordination
        intelligence klass: CityCouncil::Intelligence, args: { council: council_instance }
        operations klass: CityCouncil::Operations, args: { council: council_instance }
      end

      logger.info("VSM capsule setup completed successfully")

      # Set up VSM bus subscriptions after capsule is ready
      setup_vsm_subscriptions
    end

    def setup_messaging
      logger.info("Setting up SmartMessage subscriptions for CityCouncil")

      # Set up SmartMessage subscriptions for council requests
      if defined?(Messages::ServiceRequestMessage)
        logger.info("Subscribing to ServiceRequestMessage")
        Messages::ServiceRequestMessage.subscribe(to: @service_name) do |message|
          handle_service_request(message)
        end
      else
        logger.warn("ServiceRequestMessage not available for subscription")
      end

      # Subscribe to health checks
      if defined?(Messages::HealthCheckMessage)
        logger.info("Subscribing to HealthCheckMessage")
        Messages::HealthCheckMessage.subscribe(to: @service_name) do |message|
          respond_to_health_check(message)
        end
      else
        logger.warn("HealthCheckMessage not available for subscription")
      end

      # Subscribe to health status responses from departments
      if defined?(Messages::HealthStatusMessage)
        Messages::HealthStatusMessage.from(@service_name)

        logger.info("Subscribing to HealthStatusMessage responses")
        Messages::HealthStatusMessage.subscribe(to: @service_name) do |message|
          handle_department_health_response(message)
        end
      else
        logger.warn("HealthStatusMessage not available for subscription")
      end

      logger.info("SmartMessage subscriptions setup completed")
    end

    def setup_signal_handlers
      %w[INT TERM].each do |signal|
        Signal.trap(signal) do
          restore_terminal if respond_to?(:restore_terminal)
          puts "\n🏛️ CityCouncil shutting down..."
          logger.info("CityCouncil shutting down")
          cleanup_department_processes
          exit(0)
        end
      end
    end

    def cleanup_department_processes
      unless @department_processes.empty?
        puts "🧹 Cleaning up #{@department_processes.size} department processes..."
        @department_processes.each do |dept_name, pid|
          begin
            Process.kill("TERM", pid)
            logger.info("Terminated #{dept_name} (PID: #{pid})")
          rescue Errno::ESRCH
            # Process already dead
          rescue => e
            logger.warn("Failed to terminate #{dept_name} (PID: #{pid}): #{e.message}")
          end
        end
      end
    end

    def handle_service_request(message)
      logger.info("Received service request from #{message._sm_header.from}")
      logger.debug("Service request details: #{message.inspect}")

      puts "🏛️ 📨 CityCouncil: Received service request from #{message._sm_header.from}"

      # Process the service request with VSM Intelligence
      payload = message.details[:description] || message.description || message.inspect
      logger.info("Processing service request with VSM Intelligence: #{payload}")

      puts "🏛️ 🧠 CityCouncil: Processing request with VSM Intelligence..."
      puts "🏛️ 📋 Request content: #{payload.to_s.slice(0, 100)}#{payload.to_s.length > 100 ? '...' : ''}"

      status_line("Processing request from #{message._sm_header.from}")

      # Create VSM message and process with Intelligence
      vsm_message = VSM::Message.new(
        kind: :service_request,
        payload: payload,
        meta: { msg_id: message._sm_header.uuid }
      )

      # Process with Intelligence component
      puts "🏛️ 🎯 CityCouncil: Forwarding to Intelligence component..."
      intelligence_result = @capsule.roles[:intelligence].handle(vsm_message, bus: @capsule.bus)
      logger.debug("VSM Intelligence processing result: #{intelligence_result}")
      puts "🏛️ ✅ CityCouncil: Intelligence processing #{intelligence_result ? 'completed' : 'failed'}"

      status_line("Governing #{@existing_departments.size} departments")
    end

    # Set up VSM bus message subscriptions
    def setup_vsm_subscriptions
      logger.info("Setting up VSM bus subscriptions for CityCouncil")
      puts "🏛️ 🚌 CityCouncil: Setting up VSM bus subscriptions..."
      puts "🏛️ 🚌 Bus object ID: #{@capsule.bus.object_id}"
      # Subscribe to create_service messages and forward to Operations
      @capsule.bus.subscribe do |vsm_message|
        logger.debug("VSM Bus: Received message - kind=#{vsm_message.kind}")
        puts "🏛️ 🚌 VSM Bus: Received #{vsm_message.kind} message"
        case vsm_message.kind
        when :create_service
          # Forward to Operations component
          logger.info("VSM Bus: Forwarding create_service message to Operations component")
          logger.debug("VSM Bus: create_service payload: #{vsm_message.payload}")
          puts "🏛️ 🏗️ CityCouncil: VSM Bus routing create_service to Operations..."
          puts "🏛️ 📄 Service spec: #{vsm_message.payload[:spec][:name] rescue 'unknown'}"
          operations_result = @capsule.roles[:operations].handle(vsm_message, bus: @capsule.bus)
          logger.debug("VSM Bus: Operations processing result: #{operations_result}")
          puts "🏛️ 🔧 CityCouncil: Operations #{operations_result ? 'succeeded' : 'failed'} in handling create_service"
        when :assistant
          # Log assistant responses
          logger.info("VSM Bus: Assistant response: #{vsm_message.payload}")
          puts "🏛️ 🤖 CityCouncil: VSM Assistant response: #{vsm_message.payload.to_s.slice(0, 80)}#{vsm_message.payload.to_s.length > 80 ? '...' : ''}"
        else
          logger.debug("VSM Bus: Unhandled message kind: #{vsm_message.kind}")
          puts "🏛️ ❓ CityCouncil: Unhandled VSM message kind: #{vsm_message.kind}"
        end
      end
    end

    def register_new_department(department_name, process_id = nil)
      dept_full_name = "#{department_name}_department"
      @existing_departments << dept_full_name unless @existing_departments.include?(dept_full_name)

      if process_id
        @department_processes[dept_full_name] = process_id
      end

      logger.info("Registered new department: #{dept_full_name}#{process_id ? " (PID: #{process_id})" : ""}")
    end

    def update_department_pid(department_name, new_pid)
      dept_full_name = "#{department_name}_department"
      if @department_processes[dept_full_name]
        old_pid = @department_processes[dept_full_name]
        @department_processes[dept_full_name] = new_pid
        logger.info("Updated #{dept_full_name} PID: #{old_pid} → #{new_pid}")
      else
        @department_processes[dept_full_name] = new_pid
        logger.info("Added new PID for #{dept_full_name}: #{new_pid}")
      end
    end

    def start_governance
      logger.info("Starting CityCouncil governance operations")

      puts "🏛️ City Council Active"
      puts "📋 Governing #{@existing_departments.size} departments:"
      @existing_departments.each { |dept| puts "   - #{dept}" }
      puts "🔧 Ready to create new departments as needed"
      puts "👂 Listening for service requests..."

      status_line("Governing #{@existing_departments.size} departments")

      logger.info("CityCouncil governance started successfully")

      # Start main monitoring loop
      logger.info("Starting CityCouncil main monitoring loop")
      logger.info("VSM components available for direct processing")

      # Main loop
      loop do
        monitor_city_operations
        sleep(10)
      end
    rescue => e
      logger.error("Error in CityCouncil governance loop: #{e.message}")
      logger.error("Exception backtrace: #{e.backtrace.join("\n")}")
      logger.info("Restarting governance loop after error")
      retry
    end

    private

    def monitor_city_operations
      logger.debug("Monitoring city operations - checking for new departments")

      # Periodic check of city operations
      current_departments = discover_departments

      if current_departments.size > @existing_departments.size
        new_depts = current_departments - @existing_departments
        logger.info("New departments detected during monitoring: #{new_depts.join(", ")}")
        @existing_departments = current_departments
        status_line("Governing #{@existing_departments.size} departments (new: #{new_depts.first})")
      elsif current_departments.size < @existing_departments.size
        removed_depts = @existing_departments - current_departments
        logger.warn("Departments removed/missing: #{removed_depts.join(", ")}")
        @existing_departments = current_departments
        status_line("Governing #{@existing_departments.size} departments")
      end

      # Check department health status
      health_status = get_department_health_summary
      if health_status[:unhealthy_count] > 0 || health_status[:warning_count] > 0
        health_msg = []
        health_msg << "#{health_status[:unhealthy_count]} unhealthy" if health_status[:unhealthy_count] > 0
        health_msg << "#{health_status[:warning_count]} warning" if health_status[:warning_count] > 0

        logger.warn("CityCouncil: Department health issues - #{health_msg.join(', ')}")
        status_line("#{@existing_departments.size} departments (#{health_msg.join(', ')})")
      elsif health_status[:monitored_count] > 0
        logger.debug("CityCouncil: All #{health_status[:healthy_count]} monitored departments healthy")
      end

      old_status = @status
      @status = determine_health_status
      if old_status != @status
        logger.info("CityCouncil health status changed from #{old_status} to #{@status}")
        status_line("#{@status.upcase} - #{@existing_departments.size} departments")
      end
    end

    def get_department_health_summary
      return { healthy_count: 0, unhealthy_count: 0, monitored_count: 0 } unless @capsule&.roles&.[](:operations)

      health_status = @capsule.roles[:operations].get_department_health_status
      healthy_count = 0
      unhealthy_count = 0
      warning_count = 0

      health_status.each do |dept_name, health_info|
        case health_info[:status]
        when 'running'
          if health_info[:process_healthy] && health_info[:responsive]
            healthy_count += 1
          elsif health_info[:process_healthy] || health_info[:responsive]
            warning_count += 1
          else
            unhealthy_count += 1
          end
        when 'permanently_failed'
          unhealthy_count += 1
        else
          warning_count += 1
        end
      end

      {
        healthy_count: healthy_count,
        unhealthy_count: unhealthy_count,
        warning_count: warning_count,
        monitored_count: health_status.size,
        details: health_status
      }
    end

    def determine_health_status
      # Health based on department count and responsiveness
      case @existing_departments.size
      when 0..2 then "critical"
      when 3..5 then "warning"
      else "healthy"
      end
    end

    def get_status_details
      @status = determine_health_status
      uptime = Time.now - @start_time
      details = {
        uptime: uptime.round(1),
        departments_count: @existing_departments.size,
        departments: @existing_departments,
        department_processes: @department_processes.size,
        ready: true,
      }
      [@status, details]
    end

    def respond_to_health_check(message)
      logger.info("Received health check from #{message._sm_header.from}")

      if defined?(Messages::HealthStatusMessage)
        uptime = Time.now - @start_time
        health_summary = get_department_health_summary
        status_msg = Messages::HealthStatusMessage.new(
          service_name: @service_name,
          check_id: message._sm_header.uuid,
          status: @status,
          details: {
            uptime: uptime,
            departments_count: @existing_departments.size,
            departments: @existing_departments,
            department_processes: @department_processes.size,
            health_summary: health_summary,
            ready: true,
          },
        )
        status_msg._sm_header.from = @service_name
        status_msg._sm_header.to = message._sm_header.from
        status_msg.publish

        logger.info("Responded to health check from #{message._sm_header.from}: #{@status} (#{@existing_departments.size} departments, #{uptime.round(1)}s uptime)")
      else
        logger.warn("HealthStatusMessage not available - cannot respond to health check")
      end
    end

    def handle_department_health_response(message)
      logger.debug("Received health status response from #{message._sm_header.from}")

      # Forward to Operations component for processing
      if @capsule&.roles&.[](:operations)
        dept_name = message.service_name || message._sm_header.from
        @capsule.roles[:operations].handle_health_response(dept_name, message)
        logger.debug("Forwarded health response from #{dept_name} to Operations")
      else
        logger.warn("Operations component not available to handle health response")
      end
    end
  end
end
