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
      departments = Dir.glob("*_department.rb").map do |file|
        File.basename(file, ".rb")
      end
      logger.info("Discovered #{departments.size} existing departments: #{departments.join(", ")}")
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

      # Process the service request with VSM Intelligence
      payload = message.details[:description] || message.description || message.inspect
      logger.info("Processing service request with VSM Intelligence: #{payload}")
      
      status_line("Processing request from #{message._sm_header.from}")

      # Create VSM message and process with Intelligence
      vsm_message = VSM::Message.new(
        kind: :service_request,
        payload: payload,
        meta: { msg_id: message._sm_header.uuid }
      )

      # Process with Intelligence component
      intelligence_result = @capsule.roles[:intelligence].handle(vsm_message, bus: @capsule.bus)
      logger.debug("VSM Intelligence processing result: #{intelligence_result}")
      
      status_line("Governing #{@existing_departments.size} departments")
    end

    # Set up VSM bus message subscriptions
    def setup_vsm_subscriptions
      logger.info("Setting up VSM bus subscriptions for CityCouncil")
      # Subscribe to create_service messages and forward to Operations
      @capsule.bus.subscribe do |vsm_message|
        logger.debug("VSM Bus: Received message - kind=#{vsm_message.kind}")
        case vsm_message.kind
        when :create_service
          # Forward to Operations component
          logger.info("VSM Bus: Forwarding create_service message to Operations component")
          logger.debug("VSM Bus: create_service payload: #{vsm_message.payload}")
          operations_result = @capsule.roles[:operations].handle(vsm_message, bus: @capsule.bus)
          logger.debug("VSM Bus: Operations processing result: #{operations_result}")
        when :assistant
          # Log assistant responses
          logger.info("VSM Bus: Assistant response: #{vsm_message.payload}")
        else
          logger.debug("VSM Bus: Unhandled message kind: #{vsm_message.kind}")
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

      old_status = @status
      @status = determine_health_status
      if old_status != @status
        logger.info("CityCouncil health status changed from #{old_status} to #{@status}")
        status_line("#{@status.upcase} - #{@existing_departments.size} departments")
      end
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
        status_msg = Messages::HealthStatusMessage.new(
          service_name: @service_name,
          check_id: message._sm_header.uuid,
          status: @status,
          details: {
            uptime: uptime,
            departments_count: @existing_departments.size,
            departments: @existing_departments,
            department_processes: @department_processes.size,
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
  end
end
