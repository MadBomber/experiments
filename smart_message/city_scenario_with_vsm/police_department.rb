#!/usr/bin/env ruby
# examples/multi_program_demo/police_department.rb

require_relative 'smart_message/lib/smart_message'
require_relative 'messages/health_check_message'
require_relative 'messages/health_status_message'
require_relative 'messages/silent_alarm_message'
require_relative 'messages/police_dispatch_message'
require_relative 'messages/emergency_resolved_message'
require_relative 'messages/emergency_911_message'

require_relative 'common/health_monitor'
require_relative 'common/logger'
require_relative 'common/status_line'

class PoliceDepartment
  include Common::HealthMonitor
  include Common::Logger
  include Common::StatusLine

  def initialize
    @service_name = 'police_department'
    @status = 'healthy'
    @start_time = Time.now
    @active_incidents = {}
    @available_units = ['Unit-101', 'Unit-102', 'Unit-103', 'Unit-104']

    setup_messaging
    setup_signal_handlers
    setup_health_monitor
  end


  def setup_messaging
    Messages::EmergencyResolvedMessage.from(@service_name)

    # Subscribe to silent alarms from banks
    Messages::SilentAlarmMessage.subscribe(to: @service_name) do |message|
      puts "🚔 DEBUG: Received SilentAlarmMessage to: #{message._sm_header.to}"
      handle_silent_alarm(message)
    end

    # Subscribe to 911 calls routed from dispatch
    Messages::Emergency911Message.subscribe(to: [@service_name, /police/i]) do |message|
      puts "🚔 DEBUG: Received Emergency911Message to: #{message._sm_header.to}"
      handle_911_call(message)
    end

    puts "🚔 Police Department operational"
    puts "   Available units: #{@available_units.join(', ')}"
    puts "   Responding to health checks, silent alarms, and 911 calls"
    puts "   Press Ctrl+C to stop\n\n"
    logger.info("Police Department operational with units: #{@available_units.join(', ')}")
    status_line("Ready - #{@available_units.size} units available")
  end

  def setup_signal_handlers
    %w[INT TERM].each do |signal|
      Signal.trap(signal) do
        restore_terminal if respond_to?(:restore_terminal)
        puts "\n🚔 Police Department signing off..."
        logger.info("Police Department signing off")
        exit(0)
      end
    end
  end


  def start_service
    loop do
      check_incident_resolutions
      update_status_line
      sleep(2)
    end
  rescue => e
    puts "🚔 Error in police service: #{e.message}"
    logger.error("Error in police service: #{e.message}")
    retry
  end

  private

  def service_emoji
    "🚔"
  end

  def update_status_line
    if @active_incidents.empty?
      status_line("Ready - #{@available_units.size} units available")
    else
      status_line("Active: #{@active_incidents.size} incidents, #{@available_units.size} units free")
    end
  end

  def get_status_details
    # Determine status based on available units and active incidents
    @status = if @available_units.empty?
                'critical'
              elsif @available_units.size <= 1
                'warning'
              elsif @active_incidents.size >= 3
                'warning'
              else
                'healthy'
              end

    details = case @status
             when 'healthy' then "All units operational, #{@active_incidents.size} active incidents"
             when 'warning' then "High call volume, #{@active_incidents.size} active incidents"
             when 'critical' then "Multiple emergencies, all units deployed"
             when 'failed' then "System down, emergency protocols activated"
             end

    [@status, details]
  end

  def handle_silent_alarm(alarm)
    # Process silent alarm message
    puts "🚨 SILENT ALARM: #{alarm.bank_name} at #{alarm.location} - #{alarm.alarm_type.upcase} (#{alarm.severity} severity)"
    puts "   Details: #{alarm.details}" if alarm.details
    puts "   Time: #{alarm.timestamp}"
    logger.warn("SILENT ALARM received: #{alarm.alarm_type} at #{alarm.location} (#{alarm.severity} severity)")

    # Assign available units
    units_needed = case alarm.severity
                  when 'low' then 1
                  when 'medium' then 2
                  when 'high' then 3
                  when 'critical' then 4
                  else 2
                  end

    assigned_units = @available_units.take(units_needed)
    @available_units = @available_units.drop(units_needed)

    dispatch_id = SecureRandom.hex(4)
    @active_incidents[dispatch_id] = {
      location: alarm.location,
      start_time: Time.now,
      units: assigned_units,
      type: alarm.alarm_type
    }

    # Send dispatch message
    dispatch = Messages::PoliceDispatchMessage.new(
      dispatch_id: dispatch_id,
      units_assigned: assigned_units,
      location: alarm.location,
      incident_type: alarm.alarm_type,
      priority: map_severity_to_priority(alarm.severity),
      estimated_arrival: "#{rand(3..8)} minutes",
      timestamp: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
    )
    dispatch.publish

    puts "🚔 Dispatched #{assigned_units.size} units to #{alarm.location}"
    puts "   Available units: #{@available_units.size}"
    logger.info("Dispatched units #{assigned_units.join(', ')} to #{alarm.location} (#{dispatch_id})")
    status_line("ALARM: #{alarm.alarm_type} - #{assigned_units.size} units dispatched")
  rescue => e
    puts "🚔 Error handling silent alarm: #{e.message}"
    logger.error("Error handling silent alarm: #{e.message}")
  end

  def handle_911_call(call)
    # Color code based on emergency type
    type_color = case call.emergency_type
                 when 'accident' then "\e[33m"  # Yellow
                 when 'crime' then "\e[31m"     # Red
                 else "\e[36m"                  # Cyan
                 end

    puts "\n#{type_color}🚔 911 CALL RECEIVED\e[0m from dispatch"
    puts "   📍 Location: #{call.caller_location}"
    puts "   🚨 Type: #{call.emergency_type.upcase}"
    puts "   📝 Description: #{call.description}"
    puts "   👤 Caller: #{call.caller_name || 'Unknown'}"

    logger.warn("911 Call: #{call.emergency_type} at #{call.caller_location} - #{call.description}")

    # Handle based on emergency type
    case call.emergency_type
    when 'accident'
      handle_accident_call(call)
    when 'crime'
      handle_crime_call(call)
    else
      handle_general_911_call(call)
    end
  rescue => e
    puts "🚔 Error handling 911 call: #{e.message}"
    logger.error("Error handling 911 call: #{e.message}")
  end

  def handle_accident_call(call)
    incident_id = "ACC-#{Time.now.strftime('%H%M%S')}"

    # Determine units needed based on severity
    units_needed = case call.severity
                   when 'critical' then 3
                   when 'high' then 2
                   else 1
                   end

    units_needed = [units_needed, @available_units.size].min
    assigned_units = @available_units.shift(units_needed)

    if assigned_units.empty?
      puts "🚔 ⚠️  No units available for accident response!"
      logger.error("No units available for accident at #{call.caller_location}")
      return
    end

    @active_incidents[incident_id] = {
      type: 'accident',
      location: call.caller_location,
      units: assigned_units,
      start_time: Time.now,
      call: call
    }

    puts "🚔 Dispatched #{assigned_units.join(', ')} to accident at #{call.caller_location}"
    puts "   Vehicles involved: #{call.vehicles_involved || 'Unknown'}"
    puts "   Injuries: #{call.injuries_reported ? 'Yes' : 'No'}"
    logger.info("Dispatched #{assigned_units.join(', ')} to accident #{incident_id}")
    status_line("ACCIDENT: #{assigned_units.size} units dispatched")
  end

  def handle_crime_call(call)
    incident_id = "CRM-#{Time.now.strftime('%H%M%S')}"

    # Determine units based on severity and weapons
    units_needed = call.weapons_involved ? 3 : 2
    units_needed = [units_needed, @available_units.size].min
    assigned_units = @available_units.shift(units_needed)

    if assigned_units.empty?
      puts "🚔 ⚠️  No units available for crime response!"
      logger.error("No units available for crime at #{call.caller_location}")
      return
    end

    @active_incidents[incident_id] = {
      type: 'crime',
      location: call.caller_location,
      units: assigned_units,
      start_time: Time.now,
      call: call
    }

    puts "🚔 Dispatched #{assigned_units.join(', ')} to crime scene at #{call.caller_location}"
    puts "   Weapons involved: #{call.weapons_involved ? 'YES' : 'No'}"
    puts "   Suspects on scene: #{call.suspects_on_scene ? 'YES' : 'Unknown'}"
    logger.info("Dispatched #{assigned_units.join(', ')} to crime #{incident_id}")
    status_line("CRIME: #{assigned_units.size} units dispatched")
  end

  def handle_general_911_call(call)
    incident_id = "GEN-#{Time.now.strftime('%H%M%S')}"

    assigned_units = @available_units.shift(1)

    if assigned_units.empty?
      puts "🚔 ⚠️  No units available for response!"
      logger.error("No units available for call at #{call.caller_location}")
      return
    end

    @active_incidents[incident_id] = {
      type: call.emergency_type,
      location: call.caller_location,
      units: assigned_units,
      start_time: Time.now,
      call: call
    }

    puts "🚔 Dispatched #{assigned_units.join(', ')} to #{call.emergency_type} at #{call.caller_location}"
    logger.info("Dispatched #{assigned_units.join(', ')} to #{call.emergency_type} #{incident_id}")
  end

  def check_incident_resolutions
    @active_incidents.each do |incident_id, incident|
      # Simulate incident resolution after 10-15 seconds
      duration = (Time.now - incident[:start_time]).to_i
      if duration > rand(10..15)
        resolve_incident(incident_id, incident, duration)
      end
    end
  end

  def resolve_incident(incident_id, incident, duration_seconds)
    # Return units to available pool
    @available_units.concat(incident[:units])
    @active_incidents.delete(incident_id)

    outcomes = ['Suspects apprehended', 'False alarm - all clear', 'Incident resolved peacefully', 'Suspects fled scene']

    resolution = Messages::EmergencyResolvedMessage.new(
      incident_id: incident_id,
      incident_type: incident[:type],
      location: incident[:location],
      resolved_by: @service_name,
      resolution_time: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      duration_minutes: (duration_seconds / 60.0).round(1),
      outcome: outcomes.sample,
      units_involved: incident[:units],
    )
    resolution.publish

    puts "🚔 Incident #{incident_id} resolved after #{(duration_seconds / 60.0).round(1)} minutes"
    puts "   Units #{incident[:units].join(', ')} now available"
    logger.info("Incident #{incident_id} resolved: #{outcomes.last} after #{(duration_seconds / 60.0).round(1)} minutes")
  rescue => e
    puts "🚔 Error resolving incident: #{e.message}"
    logger.error("Error resolving incident: #{e.message}")
  end

  def map_severity_to_priority(severity)
    case severity
    when 'low' then 'low'
    when 'medium' then 'medium'
    when 'high' then 'high'
    when 'critical' then 'emergency'
    else 'medium'
    end
  end
end

if __FILE__ == $0
  police_dept = PoliceDepartment.new
  police_dept.start_service
end
