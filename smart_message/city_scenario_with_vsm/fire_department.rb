#!/usr/bin/env ruby
# examples/multi_program_demo/fire_department.rb

require_relative 'smart_message/lib/smart_message'

require_relative 'messages/health_check_message'
require_relative 'messages/health_status_message'
require_relative 'messages/fire_emergency_message'
require_relative 'messages/fire_dispatch_message'
require_relative 'messages/emergency_resolved_message'
require_relative 'messages/emergency_911_message'

require_relative 'common/health_monitor'
require_relative 'common/logger'
require_relative 'common/status_line'

class FireDepartment
  include Common::HealthMonitor
  include Common::Logger
  include Common::StatusLine

  def initialize
    @service_name = 'fire_department'
    @status       = 'healthy'
    @start_time   = Time.now
    @active_fires = {}
    @available_engines = ['Engine-1', 'Engine-2', 'Engine-3', 'Ladder-1', 'Rescue-1']

    setup_messaging
    setup_signal_handlers
    setup_health_monitor
  end

  # def setup_logging
  #   log_file = File.join(__dir__, 'fire_department.log')
  #   logger  = Logger.new(log_file)
  #   logger.level = Logger::INFO
  #   logger.formatter = proc do |severity, datetime, progname, msg|
  #     "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{msg}\n"
  #   end
  #   logger.info("Fire Department logging started")
  # end

  def setup_messaging
    Messages::FireDispatchMessage.from      = @service_name
    Messages::EmergencyResolvedMessage.from = @service_name

    # Subscribe to fire emergencies from houses
    Messages::FireEmergencyMessage.subscribe(to: [@service_name, /fire/i]) do |message|
      handle_fire_emergency(message)
    end

    # Subscribe to 911 calls routed from dispatch (medical, rescue, hazmat)
    Messages::Emergency911Message.subscribe(to: [@service_name, /medical|rescue|hazmat/i]) do |message|
      handle_911_call(message)
    end

    puts "🚒 Fire Department ready for service"
    puts "   Available engines: #{@available_engines.join(', ')}"
    puts "   Responding to health checks, fire emergencies, and 911 medical/rescue calls"
    puts "   Press Ctrl+C to stop\n\n"
    logger.info("Fire Department ready for service with engines: #{@available_engines.join(', ')}")
    status_line("Ready - #{@available_engines.size} engines available")
  end

  def setup_signal_handlers
    %w[INT TERM].each do |signal|
      Signal.trap(signal) do
        restore_terminal if respond_to?(:restore_terminal)
        puts "\n🚒 Fire Department out of service..."
        logger.info("Fire Department out of service")
        exit(0)
      end
    end
  end


  def start_service
    loop do
      check_fire_resolutions
      update_status_line
      sleep(3)
    end
  rescue => e
    puts "🚒 Error in fire service: #{e.message}"
    logger.error("Error in fire service: #{e.message}")
    retry
  end

  private

  def service_emoji
    "🚒"
  end

  def update_status_line
    if @active_fires.empty?
      status_line("Ready - #{@available_engines.size} engines available")
    else
      status_line("Active: #{@active_fires.size} emergencies, #{@available_engines.size} engines free")
    end
  end

  def get_status_details
    # Status depends on active fires and available engines
    @status = if @active_fires.size >= 3
               'critical'
             elsif @active_fires.size >= 2
               'warning'
             elsif @available_engines.size < 2
               'warning'
             else
               'healthy'
             end

    details = case @status
             when 'healthy' then "All engines available, #{@active_fires.size} active fires"
             when 'warning' then "#{@available_engines.size} engines available, #{@active_fires.size} active fires"
             when 'critical' then "All engines deployed, #{@active_fires.size} major fires"
             when 'failed' then "Equipment failure, emergency mutual aid requested"
             end

    [@status, details]
  end

  def handle_fire_emergency(emergency)
    # Process fire emergency message with colored output
    severity_color = case emergency.severity
                    when 'small' then "\e[33m"      # Yellow
                    when 'medium' then "\e[93m"     # Orange
                    when 'large' then "\e[31m"      # Red
                    when 'out_of_control' then "\e[91m" # Bright red
                    else "\e[0m"
                    end

    puts "🔥 #{severity_color}FIRE EMERGENCY\e[0m: #{emergency.house_address}"
    puts "   Type: #{emergency.fire_type} | Severity: #{emergency.severity.upcase}"
    puts "   Occupants: #{emergency.occupants_status}" if emergency.occupants_status
    puts "   Spread Risk: #{emergency.spread_risk}" if emergency.spread_risk
    puts "   Time: #{emergency.timestamp}"
    logger.warn("FIRE EMERGENCY: #{emergency.fire_type} fire at #{emergency.house_address} (#{emergency.severity} severity)")

    # Determine engines needed based on fire severity
    engines_needed = case emergency.severity
                    when 'small' then 1
                    when 'medium' then 2
                    when 'large' then 3
                    when 'out_of_control' then @available_engines.size
                    else 2
                    end

    assigned_engines = @available_engines.take(engines_needed)
    @available_engines = @available_engines.drop(engines_needed)

    # Determine equipment needed
    equipment = determine_equipment_needed(emergency.fire_type, emergency.severity)

    dispatch_id = SecureRandom.hex(4)
    @active_fires[dispatch_id] = {
      address: emergency.house_address,
      start_time: Time.now,
      engines: assigned_engines,
      fire_type: emergency.fire_type,
      severity: emergency.severity
    }

    # Send dispatch message
    dispatch = Messages::FireDispatchMessage.new(
      dispatch_id: dispatch_id,
      engines_assigned: assigned_engines,
      location: emergency.house_address,
      fire_type: emergency.fire_type,
      equipment_needed: equipment,
      estimated_arrival: "#{rand(4..10)} minutes",
      timestamp: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
    )
    dispatch.publish

    puts "🚒 Dispatched #{assigned_engines.size} engines to #{emergency.house_address}"
    puts "   Fire type: #{emergency.fire_type} (#{emergency.severity})"
    puts "   Available engines: #{@available_engines.size}"
    status_line("FIRE: #{emergency.severity} - #{assigned_engines.size} engines dispatched")
    logger.info("Dispatched engines #{assigned_engines.join(', ')} to #{emergency.house_address} (#{dispatch_id})")
  rescue => e
    puts "🚒 Error handling fire emergency: #{e.message}"
    logger.error("Error handling fire emergency: #{e.message}")
  end

  def handle_911_call(call)
    # Color code based on emergency type
    type_color = case call.emergency_type
                 when 'medical' then "\e[91m"  # Bright red
                 when 'rescue' then "\e[33m"   # Yellow
                 when 'hazmat' then "\e[35m"   # Magenta
                 when 'accident' then "\e[31m" # Red (multi-car)
                 else "\e[36m"                 # Cyan
                 end

    puts "\n#{type_color}🚒 911 EMERGENCY\e[0m from dispatch"
    puts "   📍 Location: #{call.caller_location}"
    puts "   🚨 Type: #{call.emergency_type.upcase}"
    puts "   📝 Description: #{call.description}"
    puts "   👤 Caller: #{call.caller_name || 'Unknown'}"

    logger.warn("911 Emergency: #{call.emergency_type} at #{call.caller_location} - #{call.description}")

    # Handle based on emergency type
    case call.emergency_type
    when 'medical'
      handle_medical_call(call)
    when 'rescue'
      handle_rescue_call(call)
    when 'hazmat'
      handle_hazmat_call(call)
    when 'accident'
      handle_major_accident(call)
    else
      handle_general_emergency(call)
    end
  rescue => e
    puts "🚒 Error handling 911 call: #{e.message}"
    logger.error("Error handling 911 call: #{e.message}")
  end

  def handle_medical_call(call)
    incident_id = "MED-#{Time.now.strftime('%H%M%S')}"

    # Medical calls get rescue unit and potentially an engine
    units_needed = call.severity == 'critical' ? 2 : 1
    units_needed = [units_needed, @available_engines.size].min

    # Prefer Rescue unit for medical
    assigned_engines = []
    if @available_engines.include?('Rescue-1')
      assigned_engines << @available_engines.delete('Rescue-1')
      units_needed -= 1
    end
    assigned_engines.concat(@available_engines.shift(units_needed)) if units_needed > 0

    if assigned_engines.empty?
      puts "🚒 ⚠️  No units available for medical response!"
      logger.error("No units available for medical at #{call.caller_location}")
      return
    end

    @active_fires[incident_id] = {
      type: 'medical',
      location: call.caller_location,
      engines: assigned_engines,
      start_time: Time.now,
      severity: call.severity,
      call: call
    }

    puts "🚒 Dispatched #{assigned_engines.join(', ')} to medical emergency"
    puts "   Injuries: #{call.number_of_victims || 'Unknown'} victims"
    puts "   Severity: #{call.severity&.upcase || 'UNKNOWN'}"
    status_line("MEDICAL: #{assigned_engines.size} units dispatched")
    logger.info("Dispatched #{assigned_engines.join(', ')} to medical #{incident_id}")
  end

  def handle_rescue_call(call)
    incident_id = "RSC-#{Time.now.strftime('%H%M%S')}"

    # Rescue operations need ladder and rescue units
    units_needed = 2
    units_needed = [units_needed, @available_engines.size].min

    # Prefer Ladder and Rescue units
    assigned_engines = []
    ['Rescue-1', 'Ladder-1'].each do |preferred|
      if @available_engines.include?(preferred)
        assigned_engines << @available_engines.delete(preferred)
        units_needed -= 1
      end
    end
    assigned_engines.concat(@available_engines.shift(units_needed)) if units_needed > 0

    if assigned_engines.empty?
      puts "🚒 ⚠️  No units available for rescue!"
      logger.error("No units available for rescue at #{call.caller_location}")
      return
    end

    @active_fires[incident_id] = {
      type: 'rescue',
      location: call.caller_location,
      engines: assigned_engines,
      start_time: Time.now,
      severity: call.severity,
      call: call
    }

    puts "🚒 Dispatched #{assigned_engines.join(', ')} to rescue operation"
    puts "   People trapped: #{call.number_of_victims || 'Unknown'}"
    status_line("RESCUE: #{assigned_engines.size} units dispatched")
    logger.info("Dispatched #{assigned_engines.join(', ')} to rescue #{incident_id}")
  end

  def handle_hazmat_call(call)
    incident_id = "HAZ-#{Time.now.strftime('%H%M%S')}"

    # Hazmat needs multiple units
    units_needed = 3
    units_needed = [units_needed, @available_engines.size].min
    assigned_engines = @available_engines.shift(units_needed)

    if assigned_engines.empty?
      puts "🚒 ⚠️  No units available for hazmat response!"
      logger.error("No units available for hazmat at #{call.caller_location}")
      return
    end

    @active_fires[incident_id] = {
      type: 'hazmat',
      location: call.caller_location,
      engines: assigned_engines,
      start_time: Time.now,
      severity: 'high',
      call: call
    }

    puts "🚒 ⚠️  HAZMAT RESPONSE: #{assigned_engines.join(', ')} dispatched"
    puts "   Chemical hazard at #{call.caller_location}"
    logger.warn("HAZMAT incident #{incident_id} - #{assigned_engines.join(', ')} dispatched")
  end

  def handle_major_accident(call)
    incident_id = "MVA-#{Time.now.strftime('%H%M%S')}"

    # Major accidents need rescue and engines
    units_needed = call.vehicles_involved && call.vehicles_involved > 3 ? 3 : 2
    units_needed = [units_needed, @available_engines.size].min
    assigned_engines = @available_engines.shift(units_needed)

    if assigned_engines.empty?
      puts "🚒 ⚠️  No units available for accident response!"
      logger.error("No units available for accident at #{call.caller_location}")
      return
    end

    @active_fires[incident_id] = {
      type: 'accident',
      location: call.caller_location,
      engines: assigned_engines,
      start_time: Time.now,
      severity: call.severity,
      call: call
    }

    puts "🚒 Dispatched #{assigned_engines.join(', ')} to major accident"
    puts "   Vehicles: #{call.vehicles_involved || 'Multiple'}"
    puts "   Injuries: #{call.injuries_reported ? 'Yes' : 'Unknown'}"
    logger.info("Dispatched #{assigned_engines.join(', ')} to accident #{incident_id}")
  end

  def handle_general_emergency(call)
    incident_id = "EMG-#{Time.now.strftime('%H%M%S')}"

    assigned_engines = @available_engines.shift(1)

    if assigned_engines.empty?
      puts "🚒 ⚠️  No units available!"
      logger.error("No units available for emergency at #{call.caller_location}")
      return
    end

    @active_fires[incident_id] = {
      type: call.emergency_type,
      location: call.caller_location,
      engines: assigned_engines,
      start_time: Time.now,
      severity: call.severity,
      call: call
    }

    puts "🚒 Dispatched #{assigned_engines.join(', ')} to #{call.emergency_type}"
    logger.info("Dispatched #{assigned_engines.join(', ')} to #{call.emergency_type} #{incident_id}")
  end

  def check_fire_resolutions
    @active_fires.each do |fire_id, fire|
      # Fire resolution time depends on severity (10-15 seconds)
      base_time = case fire[:severity]
                 when 'small' then 10..12
                 when 'medium' then 11..13
                 when 'large' then 12..14
                 when 'out_of_control' then 13..15
                 else 11..13
                 end

      duration = (Time.now - fire[:start_time]).to_i
      if duration > rand(base_time)
        resolve_fire(fire_id, fire, duration)
      end
    end
  end

  def resolve_fire(fire_id, fire, duration_seconds)
    # Return engines to available pool
    @available_engines.concat(fire[:engines])
    @active_fires.delete(fire_id)

    outcomes = [
      'Fire extinguished successfully',
      'Fire contained with minimal damage',
      'Structure saved, investigating cause',
      'Total loss, area secured'
    ]

    resolution = Messages::EmergencyResolvedMessage.new(
      incident_id: fire_id,
      incident_type: "#{fire[:fire_type]} fire",
      location: fire[:location],
      resolved_by: @service_name,
      resolution_time: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      duration_minutes: (duration_seconds / 60.0).round(1),
      outcome: outcomes.sample,
      units_involved: fire[:engines]
    )
    resolution.publish

    puts "🚒 Fire #{fire_id} extinguished after #{(duration_seconds / 60.0).round(1)} minutes"
    puts "   Engines #{fire[:engines].join(', ')} returning to station"
    logger.info("Fire #{fire_id} extinguished: #{outcomes.last} after #{(duration_seconds / 60.0).round(1)} minutes")
  rescue => e
    puts "🚒 Error resolving fire: #{e.message}"
    logger.error("Error resolving fire: #{e.message}")
  end

  def determine_equipment_needed(fire_type, severity)
    equipment = []

    case fire_type
    when 'kitchen'
      equipment << 'Class K extinguishers'
    when 'electrical'
      equipment << 'Class C extinguishers'
      equipment << 'Power shut-off tools'
    when 'basement'
      equipment << 'Ventilation fans'
      equipment << 'Search and rescue gear'
    when 'garage'
      equipment << 'Foam suppressant'
    when 'wildfire'
      equipment << 'Brush trucks'
      equipment << 'Water tenders'
    end

    if ['large', 'out_of_control'].include?(severity)
      equipment << 'Aerial ladder'
      equipment << 'Additional water supply'
    end

    equipment.join(', ')
  end
end

if __FILE__ == $0
  fire_dept = FireDepartment.new
  fire_dept.start_service
end
