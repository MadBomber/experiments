#!/usr/bin/env ruby
# examples/multi_program_demo/health_department.rb

HEALTH_CHECK_RATE = 5 # seconds; setting to zero gets overruns and 1300+ msg/sec

require_relative 'smart_message/lib/smart_message'
require_relative 'messages/health_check_message'
require_relative 'messages/health_status_message'
require 'set'

require_relative 'common/logger'
require_relative 'common/status_line'

class HealthDepartment
  include Common::Logger
  include Common::StatusLine

  def initialize
    @service_name  = 'health-department'
    Messages::HealthCheckMessage.from = @service_name
    @check_id = 0
    @service_responses = {}  # Track last response from each service
    @non_responsive_services = Set.new  # Track services not responding

    setup_messaging
    setup_signal_handlers
  end

  def setup_logging
    log_file = File.join(__dir__, 'health_department.log')
    logger = Logger.new(log_file)
    logger.level = Logger::INFO
    logger.formatter = proc do |severity, datetime, progname, msg|
      "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{msg}\n"
    end
    logger.info("Health Department logging started")
  end

  def setup_messaging
    # Subscribe to all broadcast health status messages
    Messages::HealthStatusMessage.subscribe(broadcast: true, to: @service_name) do |message|
      # Process health status message with colored output
      status_color = case message.status
                    when 'healthy' then "\e[32m"    # Green
                    when 'warning' then "\e[33m"    # Yellow
                    when 'critical' then "\e[93m"   # Orange
                    when 'failed' then "\e[31m"     # Red
                    else "\e[0m"                     # Reset
                    end

      puts "#{status_color}#{message.service_name}: #{message.status.upcase}\e[0m #{message.details}"
      
      # Track response and check if service was previously non-responsive
      handle_service_response(message.service_name, message.status, message.details)
      
      logger.info("Received health status: #{message.service_name} = #{message.status} (#{message.details})")
      update_monitoring_status
    end

    puts "🏥 Health Department started"
    puts "   Monitoring city services health status..."
    puts "   Will send HealthCheck broadcasts every 5 seconds"
    puts "   Logging to: health_department.log"
    puts "   Press Ctrl+C to stop\n\n"
    logger.info("Health Department started monitoring city services")
    status_line("Monitoring city services")
  end

  def setup_signal_handlers
    %w[INT TERM].each do |signal|
      Signal.trap(signal) do
        restore_terminal if respond_to?(:restore_terminal)
        puts "\n🏥 Health Department shutting down..."
        logger.info("Health Department shutting down")
        exit(0)
      end
    end
  end

  def start_monitoring
    loop do
      check_for_non_responsive_services
      send_health_check
      update_monitoring_status
      sleep(HEALTH_CHECK_RATE)
    end
  rescue => e
    puts "🏥 Error in health monitoring: #{e.message}"
    logger.error("Error in health monitoring: #{e.message}")
    retry
  end

  private

  def handle_service_response(service_name, status, details)
    # Check if service was previously non-responsive
    if @non_responsive_services.include?(service_name)
      @non_responsive_services.delete(service_name)
      puts "\e[32m✓\e[0m #{service_name} is RESPONDING again"
      logger.warn("SERVICE RECOVERED: #{service_name} is now responding (status: #{status})")
    end
    
    # Update last response time and details
    @service_responses[service_name] = {
      check_id: @check_id,
      status: status,
      details: details,
      timestamp: Time.now
    }
  end

  def check_for_non_responsive_services
    # Check which services didn't respond to the last health check
    @service_responses.each do |service_name, response_data|
      # If service didn't respond to the last check (check_id is behind)
      if response_data[:check_id] < @check_id && !@non_responsive_services.include?(service_name)
        @non_responsive_services.add(service_name)
        puts "\e[31m✗\e[0m #{service_name} is NOT RESPONDING"
        logger.error("SERVICE NOT RESPONDING: #{service_name} failed to respond to health check ##{@check_id}")
      end
    end
  end

  def update_monitoring_status
    if @non_responsive_services.empty?
      if @service_responses.empty?
        status_line("Waiting for services (check ##{@check_id})")
      else
        responding_count = @service_responses.size
        status_line("✓ All #{responding_count} services healthy (check ##{@check_id})")
      end
    else
      non_responsive_list = @non_responsive_services.to_a.join(", ")
      # Status line doesn't support ANSI colors, so use plain text
      status_line("⚠ NOT RESPONDING: #{non_responsive_list}")
    end
  end

  def send_health_check
    @check_id += 1

    health_check = Messages::HealthCheckMessage.new(check_id: @check_id)

    puts
    puts "🏥 Broadcasting health check ##{@check_id} (#{health_check.uuid[0..7]}...)"
    logger.info("Broadcasting health check ##{@check_id}")

    health_check.publish
  rescue => e
    puts "🏥 Error sending health check: #{e.message}"
    logger.error("Error sending health check: #{e.message}")
  end
end

if __FILE__ == $0
  health_dept = HealthDepartment.new
  health_dept.start_monitoring
end
