#!/usr/bin/env ruby
# examples/multi_program_demo/citizen.rb

require_relative 'smart_message/lib/smart_message'
require_relative 'messages/emergency_911_message'

require_relative 'common/logger'

class Citizen
  include Common::Logger

  def initialize
    @service_name = 'citizen'
    @names = ['John Smith', 'Mary Johnson', 'Robert Williams', 'Patricia Brown', 'Michael Davis']
    @locations = [
      '123 Main Street',
      '456 Oak Avenue',
      '789 Pine Lane',
      '321 Elm Drive',
      '654 Maple Road',
      '987 Cedar Court',
      '147 Birch Way',
      '258 Spruce Boulevard'
    ]

    @emergency_scenarios = [
      # Fires
      { type: 'fire', severity: 'high',
        description: 'House is on fire! Smoke everywhere!',
        fire: true, injuries: true, victims: 2 },
      { type: 'fire', severity: 'critical',
        description: 'Kitchen grease fire spreading to cabinets!',
        fire: true, injuries: false },

      # Medical
      { type: 'medical', severity: 'critical',
        description: 'Heart attack! Person unconscious!',
        injuries: true, victims: 1 },
      { type: 'medical', severity: 'high',
        description: 'Elderly person fell down stairs, bleeding heavily',
        injuries: true, victims: 1 },

      # Crimes
      { type: 'crime', severity: 'high',
        description: 'Break-in in progress! I can see them in my neighbor\'s house!',
        weapons: false, suspects: true },
      { type: 'crime', severity: 'critical',
        description: 'Armed robbery at the corner store!',
        weapons: true, suspects: true },
      { type: 'crime', severity: 'medium',
        description: 'My car was stolen from my driveway',
        weapons: false, suspects: false },

      # Accidents
      { type: 'accident', severity: 'medium',
        description: 'Two car collision at the intersection',
        vehicles: 2, injuries: true, victims: 2 },
      { type: 'accident', severity: 'critical',
        description: 'Multi-car pileup on the highway! At least 5 cars!',
        vehicles: 5, injuries: true, victims: 8, fire: true },
      { type: 'accident', severity: 'low',
        description: 'Fender bender in parking lot',
        vehicles: 2, injuries: false },

      # Rescue
      { type: 'rescue', severity: 'high',
        description: 'Child stuck in storm drain!',
        injuries: false, victims: 1 },
      { type: 'rescue', severity: 'critical',
        description: 'Person trapped in collapsed building!',
        injuries: true, victims: 2 },

      # Hazmat
      { type: 'hazmat', severity: 'critical',
        description: 'Chemical spill from overturned truck! Strong fumes!',
        hazmat: true, injuries: true, victims: 3 },

      # Infrastructure/Utilities
      { type: 'infrastructure', severity: 'high',
        description: 'Water main break! Water flooding the street!',
        hazmat: false, injuries: false },
      { type: 'infrastructure', severity: 'critical',
        description: 'Major water line burst! Geyser shooting 20 feet high! Street is flooding!',
        hazmat: false, injuries: false, vehicles: 3 },
      { type: 'infrastructure', severity: 'medium',
        description: 'Broken water pipe in front of building, water pooling on sidewalk',
        hazmat: false, injuries: false },
      { type: 'infrastructure', severity: 'high',
        description: 'Underground water line break, road is starting to collapse!',
        hazmat: false, injuries: false, vehicles: 1 },
      
      # Environmental/Animal Control
      { type: 'other', severity: 'medium',
        description: 'Aggressive stray dog attacking people in the park',
        injuries: false },
      { type: 'other', severity: 'low',
        description: 'Dead deer on the highway causing traffic backup',
        vehicles: 10 },
      { type: 'other', severity: 'high',
        description: 'Swarm of bees has taken over playground equipment',
        injuries: false },
      
      # Public Works/Transportation
      { type: 'other', severity: 'medium',
        description: 'Large pothole opened up, cars getting damaged',
        vehicles: 3 },
      { type: 'other', severity: 'high',
        description: 'Traffic lights malfunctioning at major intersection',
        vehicles: 20 },
      { type: 'infrastructure', severity: 'medium',
        description: 'Storm drain overflowing, flooding parking lot',
        hazmat: false },
      
      # Building/Environmental
      { type: 'other', severity: 'high',
        description: 'Building facade crumbling, bricks falling on sidewalk',
        injuries: false },
      { type: 'other', severity: 'medium',
        description: 'Illegal dumping of construction debris in park',
        hazmat: false },
      { type: 'infrastructure', severity: 'critical',
        description: 'Gas leak smell near elementary school!',
        hazmat: true, injuries: false },
      
      # Parks and Recreation
      { type: 'other', severity: 'low',
        description: 'Playground equipment broken, children could get hurt',
        injuries: false },
      { type: 'other', severity: 'medium',
        description: 'Large tree branch fallen across walking trail',
        injuries: false },
      
      # General
      { type: 'other', severity: 'low',
        description: 'Suspicious person looking into car windows',
        suspects: true },
      { type: 'other', severity: 'medium',
        description: 'Power lines down across the road',
        hazmat: false }
    ]

    Messages::Emergency911Message.from = @service_name
  end

  # def setup_logging
  #   log_file = File.join(__dir__, 'citizen.log')
  #   logger = Logger.new(log_file)
  #   logger.level = Logger::INFO
  #   logger.formatter = proc do |severity, datetime, progname, msg|
  #     "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{msg}\n"
  #   end
  #   logger.info("Citizen 911 caller started")
  # end

  def make_emergency_call
    scenario = @emergency_scenarios.sample
    caller_name = @names.sample
    location = @locations.sample
    phone = "555-#{rand(1000..9999)}"

    puts "\n📱 Citizen making 911 call..."
    puts "   Caller: #{caller_name}"
    puts "   Location: #{location}"
    puts "   Emergency: #{scenario[:type]} - #{scenario[:description]}"

    call = Messages::Emergency911Message.new(
      caller_name: caller_name,
      caller_phone: phone,
      caller_location: location,
      emergency_type: scenario[:type],
      description: scenario[:description],
      severity: scenario[:severity],
      injuries_reported: scenario[:injuries],
      number_of_victims: scenario[:victims],
      fire_involved: scenario[:fire],
      weapons_involved: scenario[:weapons],
      hazardous_materials: scenario[:hazmat],
      vehicles_involved: scenario[:vehicles],
      suspects_on_scene: scenario[:suspects],
      timestamp: Time.now.iso8601,
      from: "citizen-#{caller_name.downcase.gsub(' ', '_')}",
      to: '911'
    )

    call.publish

    puts "   ✅ 911 call placed successfully"
    logger.info("911 call placed: #{scenario[:type]} at #{location} - #{scenario[:description]}")

    call
  rescue => e
    puts "   ❌ Error making 911 call: #{e.message}"
    logger.error("Error making 911 call: #{e.message}")
    nil
  end

  def run_interactive
    puts "👤 Citizen 911 Emergency Caller"
    puts "   Press Enter to make a random 911 call"
    puts "   Type 'auto' for automatic calls every 15-30 seconds"
    puts "   Type 'quit' to exit\n\n"

    loop do
      print "Action (enter/auto/quit): "
      input = gets&.chomp&.downcase

      case input
      when '', nil
        make_emergency_call
      when 'auto'
        run_automatic
        break
      when 'quit', 'q', 'exit'
        puts "👤 Citizen exiting..."
        break
      else
        puts "Unknown command. Press Enter for call, 'auto' for automatic, 'quit' to exit"
      end
    end
  end

  def run_automatic
    puts "\n👤 Starting automatic 911 calls (every 15-30 seconds)"
    puts "   Press Ctrl+C to stop\n\n"

    Signal.trap('INT') do
      puts "\n👤 Stopping automatic calls..."
      exit(0)
    end

    loop do
      make_emergency_call
      wait_time = rand(15..30)
      puts "   ⏰ Next call in #{wait_time} seconds...\n"
      sleep(wait_time)
    end
  end
end

# Run the citizen caller
if __FILE__ == $0
  citizen = Citizen.new

  # Check for command line argument
  if ARGV[0] == 'auto'
    citizen.run_automatic
  else
    citizen.run_interactive
  end
end
