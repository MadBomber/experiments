#!/usr/bin/env ruby
# examples/multi_program_demo/citizen.rb

require_relative 'smart_message/lib/smart_message'
require_relative 'messages/emergency_911_message'

require_relative 'common/logger'
require_relative 'common/status_line'

class Citizen
  include Common::Logger
  include Common::StatusLine

  def initialize(citizen_name = nil)
    @citizen_name = citizen_name || generate_random_name
    @service_name = "citizen-#{@citizen_name.downcase.gsub(' ', '_')}"
    @call_count = 0
    @status_line_prefix = @citizen_name
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

    # New scenarios for non-existent departments
    @non_existent_department_scenarios = [
      # Water Department
      { type: 'water_emergency', severity: 'critical',
        description: 'Major water main break! Entire street is flooded!',
        department: 'water_department' },
      { type: 'water_emergency', severity: 'high',
        description: 'No water pressure in entire neighborhood!',
        department: 'water_department' },
      { type: 'water_emergency', severity: 'high',
        description: 'Sewage backup in multiple homes!',
        department: 'water_department' },
        
      # Animal Control
      { type: 'animal_emergency', severity: 'high',
        description: 'Rabid raccoon attacking people!',
        department: 'animal_control' },
      { type: 'animal_emergency', severity: 'critical',
        description: 'Bear wandering through downtown!',
        department: 'animal_control' },
      { type: 'animal_emergency', severity: 'medium',
        description: 'Pack of aggressive stray dogs in schoolyard!',
        department: 'animal_control' },
        
      # Public Works
      { type: 'infrastructure_emergency', severity: 'critical',
        description: 'Bridge showing signs of collapse!',
        department: 'public_works' },
      { type: 'infrastructure_emergency', severity: 'high',
        description: 'Massive sinkhole opened up on Main Street!',
        department: 'public_works' },
      { type: 'infrastructure_emergency', severity: 'high',
        description: 'Street lights out in entire district!',
        department: 'public_works' },
        
      # Transportation Department  
      { type: 'transportation_emergency', severity: 'critical',
        description: 'Bus crashed into building downtown!',
        department: 'transportation_department' },
      { type: 'transportation_emergency', severity: 'high',
        description: 'Subway tunnel flooded, passengers trapped!',
        department: 'transportation_department' },
      { type: 'transportation_emergency', severity: 'high',
        description: 'Major traffic signal failure causing gridlock!',
        department: 'transportation_department' },
        
      # Environmental Services
      { type: 'environmental_emergency', severity: 'critical',
        description: 'Toxic waste spill near river!',
        department: 'environmental_services' },
      { type: 'environmental_emergency', severity: 'high',
        description: 'Illegal chemical dumping discovered!',
        department: 'environmental_services' },
      { type: 'environmental_emergency', severity: 'high',
        description: 'Hazardous air quality alert - smoke from unknown source!',
        department: 'environmental_services' },
        
      # Parks Department
      { type: 'parks_emergency', severity: 'high',
        description: 'Massive tree fell on playground during school hours!',
        department: 'parks_department' },
      { type: 'parks_emergency', severity: 'medium',
        description: 'Vandalism and destruction at city park!',
        department: 'parks_department' },
        
      # Sanitation Department
      { type: 'sanitation_emergency', severity: 'high',
        description: 'Garbage piling up for weeks, health hazard!',
        department: 'sanitation_department' },
      { type: 'sanitation_emergency', severity: 'critical',
        description: 'Biohazard waste dumped in residential area!',
        department: 'sanitation_department' }
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

  def make_emergency_call(force_non_existent: false)
    # 40% chance to call non-existent department, or always if forced
    use_non_existent = force_non_existent || (rand(100) < 40)
    
    scenario = if use_non_existent && !@non_existent_department_scenarios.empty?
      @non_existent_department_scenarios.sample
    else
      @emergency_scenarios.sample
    end
    caller_name = @citizen_name
    location = @locations.sample
    phone = "555-#{rand(1000..9999)}"

    puts "\n📱 Citizen making 911 call..."
    puts "   Caller: #{caller_name}"
    puts "   Location: #{location}"
    puts "   Emergency: #{scenario[:type]} - #{scenario[:description]}"
    if scenario[:department]
      puts "   🎯 Requesting: #{scenario[:department].upcase} (MAY NOT EXIST)"
    end

    call = Messages::Emergency911Message.new(
      caller_name: caller_name,
      caller_phone: phone,
      caller_location: location,
      emergency_type: scenario[:type],
      description: scenario[:description],
      severity: scenario[:severity],
      requested_department: scenario[:department],
      injuries_reported: scenario[:injuries],
      number_of_victims: scenario[:victims],
      fire_involved: scenario[:fire],
      weapons_involved: scenario[:weapons],
      hazardous_materials: scenario[:hazmat],
      vehicles_involved: scenario[:vehicles],
      suspects_on_scene: scenario[:suspects],
      timestamp: Time.now.iso8601,
      from: @service_name,
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
    puts "   Citizen: #{@citizen_name}"
    puts "   Press Enter to make a random 911 call (40% chance non-existent dept)"
    puts "   Type 'force' to force a non-existent department call"
    puts "   Type 'auto' for automatic calls every 10-20 seconds"
    puts "   Type 'quit' to exit\n\n"
    
    status_line("Ready to make 911 calls")

    loop do
      print "Action (enter/auto/quit): "
      input = gets&.chomp&.downcase

      case input
      when '', nil
        @call_count += 1
        make_emergency_call
        status_line("Made call ##{@call_count}")
      when 'force', 'f'
        @call_count += 1
        puts "\n🎯 Forcing call to NON-EXISTENT department..."
        make_emergency_call(force_non_existent: true)
        status_line("Made call ##{@call_count} (forced non-existent)")
      when 'auto'
        run_automatic
        break
      when 'quit', 'q', 'exit'
        restore_terminal if respond_to?(:restore_terminal)
        puts "👤 Citizen exiting..."
        break
      else
        puts "Unknown command. Press Enter for call, 'force' for non-existent dept, 'auto' for automatic, 'quit' to exit"
      end
    end
  end

  def run_automatic
    puts "\n👤 Starting automatic 911 calls (every 10-20 seconds)"
    puts "   Citizen: #{@citizen_name}"
    puts "   40% of calls will request non-existent departments"
    puts "   Press Ctrl+C to stop\n\n"

    Signal.trap('INT') do
      restore_terminal if respond_to?(:restore_terminal)
      puts "\n👤 Stopping automatic calls..."
      exit(0)
    end
    
    status_line("Auto mode: making calls every 10-20 seconds")

    call_count = 0
    loop do
      call_count += 1
      # Every 3rd call, definitely call a non-existent department
      force_non_existent = (call_count % 3 == 0)
      
      if force_non_existent
        puts "\n🎯 Making call to NON-EXISTENT department..."
      end
      
      make_emergency_call(force_non_existent: force_non_existent)
      wait_time = rand(10..20)  # Faster calls
      puts "   ⏰ Next call in #{wait_time} seconds...\n"
      status_line("Call ##{call_count} made, next in #{wait_time}s")
      sleep(wait_time)
    end
  end

  private

  def generate_random_name
    first_names = [
      'John', 'Mary', 'Robert', 'Patricia', 'Michael', 'Jennifer', 'William', 'Linda',
      'David', 'Elizabeth', 'Richard', 'Barbara', 'Joseph', 'Susan', 'Thomas', 'Jessica',
      'Christopher', 'Sarah', 'Daniel', 'Karen', 'Paul', 'Nancy', 'Mark', 'Lisa',
      'Donald', 'Betty', 'Steven', 'Helen', 'Kenneth', 'Sandra', 'Joshua', 'Donna'
    ]
    
    last_names = [
      'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis',
      'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas',
      'Taylor', 'Moore', 'Jackson', 'Martin', 'Lee', 'Perez', 'Thompson', 'White',
      'Harris', 'Sanchez', 'Clark', 'Ramirez', 'Lewis', 'Robinson', 'Walker', 'Young'
    ]
    
    "#{first_names.sample} #{last_names.sample}"
  end
end

# Run the citizen caller
if __FILE__ == $0
  # Allow specifying citizen name as command line argument
  citizen_name = ARGV[0] unless ARGV[0] == 'auto'
  citizen = Citizen.new(citizen_name)

  # Check for command line argument
  if ARGV.include?('auto') || (ARGV.size == 2 && ARGV[1] == 'auto')
    citizen.run_automatic
  else
    citizen.run_interactive
  end
end
