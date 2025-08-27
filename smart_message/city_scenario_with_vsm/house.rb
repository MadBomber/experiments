#!/usr/bin/env ruby
# examples/multi_program_demo/house.rb

require_relative 'smart_message/lib/smart_message'
require_relative 'messages/fire_emergency_message'
require_relative 'messages/fire_dispatch_message'

require_relative 'common/health_monitor'
require_relative 'common/logger'
require_relative 'common/status_line'

class House
  include Common::HealthMonitor
  include Common::Logger
  include Common::StatusLine

  def initialize(address = nil)
    @address = address || generate_random_address
    @service_name = "house-#{@address.gsub(/\s+/, '-').downcase}"
    @status = 'healthy'
    @start_time = Time.now
    @fire_active = false
    @last_fire_time = nil
    @occupants = rand(1..4)
    @occupant_status = 'safe'
    @status_line_prefix = @address

    setup_messaging
    setup_signal_handlers
    setup_health_monitor
  end

  # def setup_logging
  #   # Create log file name based on address (sanitized)
  #   address_slug = @address.gsub(/\s+/, '_').gsub(/[^\w\-_]/, '').downcase
  #   log_file = File.join(__dir__, "house_#{address_slug}.log")
  #   logger = Logger.new(log_file)
  #   logger.level = Logger::INFO
  #   logger.formatter = proc do |severity, datetime, progname, msg|
  #     "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{msg}\n"
  #   end
  #   logger.info("House at #{@address} logging started")
  # end

  def setup_messaging
    Messages::FireEmergencyMessage.from = @service_name

    # Subscribe to fire dispatch responses
    Messages::FireDispatchMessage.subscribe(to: @service_name) do |message|
      handle_fire_response(message)
    end

    address_slug = @address.gsub(/\s+/, '_').gsub(/[^\w\-_]/, '').downcase
    puts "🏠 House at #{@address} monitoring systems active"
    puts "   Occupants: #{@occupants}"
    puts "   Status: #{@occupant_status}"
    puts "   Press Ctrl+C to shutdown monitoring\n\n"
    logger.info("House monitoring started: #{@occupants} occupants, status: #{@occupant_status}")
  end

  def setup_signal_handlers
    %w[INT TERM].each do |signal|
      Signal.trap(signal) do
        puts "\n🏠 #{@address} monitoring system shutting down..."
        logger.info("House monitoring system shutting down")
        exit(0)
      end
    end
  end


  def start_monitoring
    loop do
      simulate_house_activity
      sleep(rand(15..45))  # Random events every 15-45 seconds
    end
  rescue => e
    puts "🏠 Error in house monitoring: #{e.message}"
    logger.error("Error in house monitoring: #{e.message}")
    retry
  end

  private

  def service_emoji
    "🏠"
  end

  def generate_random_address
    street_numbers = (100..999).to_a
    street_names = [
      'Oak Street', 'Maple Avenue', 'Pine Lane', 'Cedar Drive', 'Elm Court',
      'Birch Road', 'Willow Way', 'Ash Boulevard', 'Cherry Street', 'Poplar Lane'
    ]
    "#{street_numbers.sample} #{street_names.sample}"
  end

  def get_status_details
    # Status depends on fire situation and occupant safety
    @status = if @fire_active
               'critical'
             elsif @occupant_status.include?('trapped') || @occupant_status.include?('rescued')
               'warning'
             else
               'healthy'
             end

    details = case @status
             when 'healthy' then "All systems normal, #{@occupants} occupants #{@occupant_status}"
             when 'warning' then "Emergency response active, #{@occupants} occupants #{@occupant_status}"
             when 'critical' then "FIRE DETECTED - #{@occupants} occupants status: #{@occupant_status}"
             when 'failed' then "Power outage, backup systems failed"
             end

    [@status, details]
  end

  def simulate_house_activity
    # Only start fires occasionally and not too frequently
    return if @fire_active
    return if @last_fire_time && (Time.now - @last_fire_time) < 600  # 10 minutes minimum between fires

    # 6% chance of fire
    if rand(100) < 6
      start_fire
    else
      # Normal house activities
      activities = [
        'Security system armed',
        'Temperature adjusted',
        'Motion detected - normal activity',
        'Smoke detector test completed',
        'Door/window sensor check',
        'All systems operational'
      ]
      activity = activities.sample
      puts "🏠 #{activity}"
      logger.info("Normal activity: #{activity}")
    end
  end

  def start_fire
    @fire_active = true
    @last_fire_time = Time.now

    fire_types = ['kitchen', 'electrical', 'basement', 'garage']
    severities = ['small', 'medium', 'large']

    # Garage fires tend to be more severe
    fire_type = fire_types.sample
    severity = if fire_type == 'garage'
                ['medium', 'large', 'out_of_control'].sample
              else
                severities.sample
              end

    # Determine occupant status based on fire severity and time of day
    hour = Time.now.hour
    if severity == 'out_of_control' || (hour >= 22 || hour <= 6)  # Night time
      @occupant_status = ['safe - evacuated', 'trapped - need rescue'].sample
    else
      @occupant_status = 'safe - evacuated'
    end

    # Determine spread risk
    spread_risk = case severity
                 when 'small' then 'Low risk to neighboring structures'
                 when 'medium' then 'Moderate risk if not contained quickly'
                 when 'large' then 'High risk to adjacent buildings'
                 when 'out_of_control' then 'EXTREME RISK - evacuate neighbors'
                 end

    emergency = Messages::FireEmergencyMessage.new(
      house_address: @address,
      fire_type: fire_type,
      severity: severity,
      timestamp: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      occupants_status: @occupant_status,
      spread_risk: spread_risk,
    )
    emergency.publish

    puts "🏠 🔥 FIRE EMERGENCY 🔥"
    puts "   Address: #{@address}"
    puts "   Type: #{fire_type.upcase}"
    puts "   Severity: #{severity.upcase}"
    puts "   Occupants: #{@occupant_status}"
    puts "   Spread Risk: #{spread_risk}"
    logger.warn("FIRE EMERGENCY: #{fire_type} fire (#{severity}) - Occupants: #{@occupant_status}")
  rescue => e
    puts "🏠 Error starting fire emergency: #{e.message}"
    logger.error("Error starting fire emergency: #{e.message}")
  end

  def handle_fire_response(dispatch)
    # Process fire dispatch message
    puts "🚒 \e[31mFIRE DISPATCH\e[0m ##{dispatch.dispatch_id}"
    puts "   Engines: #{dispatch.engines_assigned.join(', ')}"
    puts "   Location: #{dispatch.location}"
    puts "   Fire Type: #{dispatch.fire_type}"
    puts "   Equipment: #{dispatch.equipment_needed}" if dispatch.equipment_needed
    puts "   ETA: #{dispatch.estimated_arrival}" if dispatch.estimated_arrival
    puts "   Dispatched: #{dispatch.timestamp}"

    puts "🏠 Fire department response received"
    puts "   #{dispatch.engines_assigned.size} engines dispatched"
    puts "   ETA: #{dispatch.estimated_arrival}"
    puts "   Equipment: #{dispatch.equipment_needed}"
    logger.info("Fire department response: #{dispatch.engines_assigned.join(', ')} dispatched, ETA #{dispatch.estimated_arrival}")

    # If occupants were trapped, fire department rescues them
    if @occupant_status.include?('trapped')
      @occupant_status = 'rescued by fire department'
      puts "🏠 🚒 Occupants successfully rescued!"
      logger.info("Occupants rescued by fire department")
    end

    # Simulate fire resolution when fire department arrives
    Thread.new do
      sleep(rand(300..900))  # 5-15 minutes for fire suppression
      extinguish_fire
    end
  rescue => e
    puts "🏠 Error handling fire response: #{e.message}"
    logger.error("Error handling fire response: #{e.message}")
  end

  def extinguish_fire
    @fire_active = false
    @occupant_status = 'safe'

    puts "🏠 ✅ Fire extinguished by fire department"
    puts "   All occupants accounted for and safe"
    puts "   House systems returning to normal"
    logger.info("Fire extinguished, all occupants safe, returning to normal")
  rescue => e
    puts "🏠 Error extinguishing fire: #{e.message}"
    logger.error("Error extinguishing fire: #{e.message}")
  end
end

if __FILE__ == $0
  # Allow specifying address as command line argument
  address = ARGV[0]
  house = House.new(address)
  house.start_monitoring
end
