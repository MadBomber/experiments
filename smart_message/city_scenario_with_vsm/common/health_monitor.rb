#!/usr/bin/env ruby
# examples/multi_program_demo/common/health_monitor.rb
# A common module used for system health monitoring
#
# Any class that inclues this module MUST define a method named get_status_details
# which is works like this:
#
# def get_status_details
#   # calculate @status and @details
#   [@status, @details]
# end
#
# The class MUST also have an instance variable @service_name
#

require_relative '../messages/health_check_message'
require_relative '../messages/health_status_message'

module Common
  module HealthMonitor
    FAIL_SAFE = 15 # seconds

    def setup_health_monitor
      @health_timer_mutex = Mutex.new
      @health_timer       = nil

      Messages::HealthCheckMessage.subscribe(broadcast: true) do |message|
        respond_to_health_check(message)
      end

      Messages::HealthStatusMessage.from = @service_name

      start_health_countdown_timer
    end

    def start_health_countdown_timer
      @health_timer_mutex.synchronize do
        @health_timer&.kill  # Kill existing timer if any
        @health_timer = Thread.new do
          sleep(FAIL_SAFE)
          shutdown_due_to_health_failure
        end
      end
    end

    def reset_health_timer
      start_health_countdown_timer
    end

    def shutdown_due_to_health_failure
      emoji = respond_to?(:service_emoji) ? service_emoji : "🔧"
      warning_message = "⚠️  WARNING: No health checks received for over #{FAIL_SAFE} seconds!"
      puts "\n#{warning_message}"
      puts "#{emoji} #{self.class.name} services are going offline..."
      @logger.fatal(warning_message)
      @logger.fatal("#{self.class.name} shutting down - no health checks received")
      exit(1)
    end

    def respond_to_health_check(health_check)
      reset_health_timer

      status, details = get_status_details

      status_msg = Messages::HealthStatusMessage.new(
        service_name:    @service_name,
        status:          status,
        check_id:        health_check.check_id,
        details:         details
      )

      status_msg.publish
      @logger.info("Sent health status: #{status} (#{details})")
    rescue => e
      emoji = respond_to?(:service_emoji) ? service_emoji : "🔧"
      puts "#{emoji} Error responding to health check: #{e.message}"
      @logger.error("Error responding to health check: #{e.message}")
    end
  end
end
