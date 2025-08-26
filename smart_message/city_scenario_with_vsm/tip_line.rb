#!/usr/bin/env ruby
# tip_line.rb - Anonymous Tip Line CLI for reporting to 911 Emergency Dispatch

require 'optparse'
require 'readline'
require 'colorize'
require 'securerandom'
require 'io/console'
require_relative 'smart_message/lib/smart_message'
require_relative 'common/logger'

begin
  require 'tty-prompt'
  require 'tty-box'
  require 'tty-screen'
  require 'tty-cursor'
  require 'tty-spinner'
  TTY_AVAILABLE = true
rescue LoadError
  TTY_AVAILABLE = false
  puts "TUI gems not available. Install with: gem install tty-prompt tty-box tty-screen tty-cursor tty-spinner"
end

# Load all message classes
Dir['messages/*.rb'].each { |f| require_relative f }

class AnonymousTipLine
  include Common::Logger
  
  def initialize
    setup_logger(name: 'tip_line', level: ::Logger::INFO)
    @available_messages = discover_message_classes
    @tip_session_id = SecureRandom.hex(4)
    
    if TTY_AVAILABLE
      @prompt = TTY::Prompt.new(symbols: { marker: '❯' }, active_color: :cyan)
      @cursor = TTY::Cursor
      @screen_width = TTY::Screen.width
      @screen_height = TTY::Screen.height
    end
    
    # Setup graceful shutdown handling
    setup_signal_handlers
    
    logger.info("Anonymous Tip Line session started - Session ID: #{@tip_session_id}")
    logger.info("Discovered #{@available_messages.length} available message types")
  end

  def setup_signal_handlers
    # Handle Ctrl+C (SIGINT) gracefully
    Signal.trap('INT') do
      puts "\n\n📞 Received interrupt signal..."
      graceful_shutdown
    end
    
    # Handle SIGTERM gracefully
    Signal.trap('TERM') do
      puts "\n📞 Received termination signal..."
      graceful_shutdown
    end
  end
  
  def graceful_shutdown
    logger.info("Tip cancelled by user (Interrupt) - Session: #{@tip_session_id}")
    
    if TTY_AVAILABLE && defined?(@cursor)
      print @cursor.show
      print @cursor.move_to(0, TTY::Screen.height)
    end
    
    puts "\n👋 Anonymous Tip Line session ended."
    puts "   Session ID: #{@tip_session_id}"
    puts "   Thank you for keeping your community safe! 🏘️"
    
    exit(0)
  end

  def run
    if TTY_AVAILABLE
      run_with_tui
    else
      run_with_basic_interface
    end
  end

  private

  def run_with_tui
    clear_screen
    display_welcome_tui
    logger.info("TUI tip line interface started for session: #{@tip_session_id}")
    
    loop do
      message_class = select_message_type_tui
      if message_class.nil?
        logger.info("User chose to exit tip line session: #{@tip_session_id}")
        break
      end
      
      logger.info("User selected message type: #{message_class.name} - Session: #{@tip_session_id}")
      
      begin
        message = build_message_interactively_tui(message_class)
        if message
          logger.info("Message built successfully for session: #{@tip_session_id}")
          confirm_and_publish_tui(message)
        else
          logger.warn("Message building cancelled for session: #{@tip_session_id}")
        end
      rescue Interrupt
        show_notification("🛡️  Tip cancelled. Your anonymity is protected.", :yellow)
        logger.info("Tip cancelled by user (Interrupt) - Session: #{@tip_session_id}")
      rescue => e
        # Only log the error, don't show notification to avoid duplicates
        logger.error("Error processing tip for session #{@tip_session_id}: #{e.class.name} - #{e.message}")
        logger.debug("Error backtrace: #{e.backtrace.join("\n")}")
      end
      
      break unless continue_tui?
    end
    
    display_goodbye_tui
    logger.info("Anonymous Tip Line session ended - Session ID: #{@tip_session_id}")
  end

  def run_with_basic_interface
    display_welcome
    logger.info("Basic tip line interface started for session: #{@tip_session_id}")
    
    loop do
      message_class = select_message_type
      if message_class.nil?
        logger.info("User chose to exit tip line session: #{@tip_session_id}")
        break
      end
      
      logger.info("User selected message type: #{message_class.name} - Session: #{@tip_session_id}")
      
      begin
        message = build_message_interactively(message_class)
        if message
          logger.info("Message built successfully for session: #{@tip_session_id}")
          confirm_and_publish(message)
        else
          logger.warn("Message building cancelled for session: #{@tip_session_id}")
        end
      rescue Interrupt
        puts "\nTip cancelled. Your anonymity is protected.".yellow
        logger.info("Tip cancelled by user (Interrupt) - Session: #{@tip_session_id}")
      rescue => e
        puts "Error processing tip: #{e.message}".red
        logger.error("Error processing tip for session #{@tip_session_id}: #{e.class.name} - #{e.message}")
        logger.debug("Error backtrace: #{e.backtrace.join("\n")}")
      end
      
      break unless continue?
    end
    
    puts "\nThank you for helping keep our community safe.".green
    puts "Your tip session ID: #{@tip_session_id}".blue
    logger.info("Anonymous Tip Line session ended - Session ID: #{@tip_session_id}")
  end

  # TUI Helper Methods
  def clear_screen
    print @cursor.clear_screen if @cursor
    print @cursor.move_to(0, 0) if @cursor
  end

  def show_notification(message, color = :cyan)
    return unless TTY_AVAILABLE
    
    # Calculate width more conservatively
    safe_width = [@screen_width - 8, 80].min
    box_width = [message.length + 6, safe_width].max
    
    box = TTY::Box.frame(
      width: box_width,
      height: 3,
      align: :center,
      padding: [0, 1],
      style: {
        fg: color,
        border: {
          fg: color
        }
      }
    ) { message }
    
    puts box
    sleep 1.5  # Slightly shorter pause
  end

  def display_welcome_tui
    return unless TTY_AVAILABLE
    
    title = "🚨 ANONYMOUS TIP LINE 🚨"
    subtitle = "Emergency Dispatch Center"
    
    main_box = TTY::Box.frame(
      width: [@screen_width - 8, 70].min,
      align: :center,
      padding: [1, 2],
      style: {
        fg: :bright_cyan,
        border: {
          fg: :bright_blue,
          type: :thick
        }
      }
    ) do
      [
        title.center(64),
        subtitle.center(64),
        "",
        "🔒 Report suspicious activity anonymously",
        "🛡️  Your identity is protected",
        "📞 Tips forwarded to Emergency Dispatch",
        "",
        "Session ID: #{@tip_session_id}".center(64)
      ].join("\n")
    end
    
    puts main_box
    puts
    
    # Press any key to continue
    begin
      @prompt.keypress("Press any key to continue...", keys: [:return, :space, :escape, :enter])
    rescue TTY::Reader::InputInterrupt
      # Handle Ctrl+C gracefully during keypress
      graceful_shutdown
    end
  end

  def display_goodbye_tui
    return unless TTY_AVAILABLE
    
    clear_screen
    
    goodbye_box = TTY::Box.frame(
      width: [@screen_width - 8, 54].min,
      height: 8,
      align: :center,
      padding: [1, 2],
      style: {
        fg: :bright_green,
        border: {
          fg: :green,
          type: :thick
        }
      }
    ) do
      [
        "🙏 THANK YOU FOR HELPING",
        "   KEEP OUR COMMUNITY SAFE",
        "",
        "Session: #{@tip_session_id}",
        "",
        "Stay safe! 👮‍♀️🚒"
      ].join("\n")
    end
    
    puts goodbye_box
    puts
  end

  def display_welcome
    puts ""
    puts "═" * 60
    puts "    ANONYMOUS TIP LINE - EMERGENCY DISPATCH CENTER".bold.blue
    puts "═" * 60
    puts ""
    puts "Report suspicious activity, crimes, emergencies anonymously"
    puts "Your identity is protected - no personal info required"
    puts ""
  end

  def discover_message_classes
    message_classes = []
    ObjectSpace.each_object(Class) do |klass|
      if klass < SmartMessage::Base && klass.name&.include?('Messages::')
        message_classes << klass
      end
    end
    message_classes.sort_by(&:name)
  end

  def select_message_type_tui
    return unless TTY_AVAILABLE
    
    clear_screen
    
    # Create menu options
    choices = @available_messages.map do |msg_class|
      name = msg_class.name.split('::').last.gsub(/Message$/, '')
      description = get_class_description(msg_class)
      emoji = get_emoji_for_message_type(name)
      {
        name: "#{emoji} #{name} - #{description}",
        value: msg_class
      }
    end
    
    choices << { name: "❌ Exit", value: nil }
    
    logger.debug("Displaying TUI message type selection menu - Session: #{@tip_session_id}")
    
    begin
      selection = @prompt.select(
        "🚨 What type of tip would you like to report?",
        choices,
        per_page: 10,
        cycle: true,
        show_help: :always,
        help: "(Use ↑/↓ arrow keys, Enter to select, q to quit)"
      )
    rescue TTY::Reader::InputInterrupt
      # Handle Ctrl+C gracefully during selection
      graceful_shutdown
    end
    
    if selection
      logger.info("User selected message type: #{selection.name} - Session: #{@tip_session_id}")
    else
      logger.info("User selected Exit option - Session: #{@tip_session_id}")
    end
    
    selection
  end

  def select_message_type
    puts "What type of tip would you like to report?".bold
    puts ""
    
    @available_messages.each_with_index do |msg_class, index|
      name = msg_class.name.split('::').last.gsub(/Message$/, '')
      description = get_class_description(msg_class)
      puts "#{index + 1}. #{name.green} - #{description}"
    end
    puts "#{@available_messages.length + 1}. Exit".red
    puts ""
    
    logger.debug("Displaying message type selection menu - Session: #{@tip_session_id}")
    
    loop do
      print "Select option (1-#{@available_messages.length + 1}): "
      choice = gets.chomp.to_i
      
      logger.debug("User input received: #{choice} - Session: #{@tip_session_id}")
      
      if choice == @available_messages.length + 1
        logger.info("User selected Exit option - Session: #{@tip_session_id}")
        return nil
      elsif choice.between?(1, @available_messages.length)
        selected = @available_messages[choice - 1]
        logger.info("User selected message type: #{selected.name} - Session: #{@tip_session_id}")
        return selected
      else
        puts "Invalid choice. Please try again.".red
        logger.warn("Invalid choice entered: #{choice} - Session: #{@tip_session_id}")
      end
    end
  end

  def get_emoji_for_message_type(name)
    case name
    when /Emergency911/
      "🆘"
    when /Fire/
      "🔥"
    when /Police/
      "👮‍♀️"
    when /Health/
      "🏥"
    when /Service.*Request/
      "🏛️"
    else
      "📝"
    end
  end

  def get_class_description(msg_class)
    # Try to get the description from the class
    if msg_class.respond_to?(:class_description)
      msg_class.class_description
    else
      # Fallback to a generic description based on class name
      name = msg_class.name.split('::').last
      case name
      when /Emergency911/
        "Emergency situations requiring immediate response"
      when /Service.*Request/
        "Request for city services or new departments"
      when /Fire/
        "Fire-related emergencies and incidents"
      when /Police/
        "Crime, suspicious activity, law enforcement matters"
      when /Health/
        "Public health concerns and medical emergencies"
      else
        "General tip or report"
      end
    end
  end

  def build_message_interactively_tui(message_class)
    return unless TTY_AVAILABLE
    
    class_name = message_class.name.split('::').last.gsub(/Message$/, '')
    clear_screen
    
    # Display message type header
    emoji = get_emoji_for_message_type(class_name)
    header_box = TTY::Box.frame(
      width: [@screen_width - 4, 70].min,
      align: :center,
      padding: [0, 1],
      style: {
        fg: :bright_yellow,
        border: {
          fg: :yellow,
          type: :thick
        }
      }
    ) { "#{emoji} ANONYMOUS TIP: #{class_name.upcase} #{emoji}" }
    
    puts header_box
    puts
    
    logger.info("Building #{class_name} message with TUI - Session: #{@tip_session_id}")
    
    properties = {}
    
    message_class.properties.each do |property_name|
      next if property_name == :_sm_header
      
      logger.debug("Prompting for property: #{property_name} - Session: #{@tip_session_id}")
      value = prompt_for_property_tui(message_class, property_name)
      
      # Only set property if we have a meaningful value
      if value && !value.to_s.strip.empty?
        properties[property_name] = value
        # Log property value but sanitize sensitive info
        safe_value = sanitize_for_logging(property_name, value)
        logger.debug("Property #{property_name} set: #{safe_value} - Session: #{@tip_session_id}")
      else
        logger.debug("Property #{property_name} skipped (empty/nil) - Session: #{@tip_session_id}")
      end
    end
    
    # Add anonymous tip metadata
    properties[:from] = 'Anonymous Tip Line'
    properties[:to] = '911'  # Match the emergency dispatch center subscription
    properties[:call_id] = @tip_session_id if properties.has_key?(:call_id)
    
    logger.info("Anonymous tip metadata added - Session: #{@tip_session_id}")
    
    # Create the message
    message = message_class.new(**properties)
    logger.info("Message instance created successfully - Session: #{@tip_session_id}")
    
    message
  rescue => e
    logger.error("Error building message for session #{@tip_session_id}: #{e.class.name} - #{e.message}")
    logger.debug("Build message error backtrace: #{e.backtrace.join("\n")}")
    # Show single error notification here
    show_notification("❌ Error building message: #{e.message}", :red)
    nil  # Return nil instead of raising to prevent duplicate error handling
  end

  def build_message_interactively(message_class)
    class_name = message_class.name.split('::').last.gsub(/Message$/, '')
    puts ""
    puts "─" * 50
    puts "ANONYMOUS TIP: #{class_name.upcase}".bold.cyan
    puts "─" * 50
    puts ""
    
    logger.info("Building #{class_name} message - Session: #{@tip_session_id}")
    
    properties = {}
    
    message_class.properties.each do |property_name|
      next if property_name == :_sm_header
      
      logger.debug("Prompting for property: #{property_name} - Session: #{@tip_session_id}")
      value = prompt_for_property(message_class, property_name)
      
      if value && !value.to_s.empty?
        properties[property_name] = value
        # Log property value but sanitize sensitive info
        safe_value = sanitize_for_logging(property_name, value)
        logger.debug("Property #{property_name} set: #{safe_value} - Session: #{@tip_session_id}")
      else
        logger.debug("Property #{property_name} skipped (empty/nil) - Session: #{@tip_session_id}")
      end
    end
    
    # Add anonymous tip metadata
    properties[:from] = 'Anonymous Tip Line'
    properties[:to] = '911'  # Match the emergency dispatch center subscription
    properties[:call_id] = @tip_session_id if properties.has_key?(:call_id)
    
    logger.info("Anonymous tip metadata added - Session: #{@tip_session_id}")
    
    # Create the message
    message = message_class.new(**properties)
    logger.info("Message instance created successfully - Session: #{@tip_session_id}")
    
    message
  rescue => e
    logger.error("Error building message for session #{@tip_session_id}: #{e.class.name} - #{e.message}")
    logger.debug("Build message error backtrace: #{e.backtrace.join("\n")}")
    raise
  end

  def prompt_for_property_tui(message_class, property_name)
    return unless TTY_AVAILABLE
    
    property_config = get_property_config(message_class, property_name)
    
    description = property_config[:description] || property_name.to_s.humanize
    required = property_config[:required] || false
    validate = property_config[:validate]
    default = property_config[:default]
    
    # Create prompt text with required indicator
    prompt_text = property_name.to_s.humanize
    if required
      prompt_text = "#{prompt_text} (REQUIRED)".colorize(:red)
    end
    
    # Handle different input types
    if %w[injuries_reported fire_involved weapons_involved suspects_on_scene].include?(property_name.to_s)
      # Boolean yes/no questions
      question_text = required ? "#{prompt_text}: #{description}" : "#{prompt_text}: #{description} (optional)"
      begin
        return @prompt.yes?(question_text)
      rescue TTY::Reader::InputInterrupt
        # Handle Ctrl+C gracefully during yes/no prompt
        graceful_shutdown
      end
    elsif validate && validate.is_a?(Proc) && property_config[:validation_message]
      # Selection from valid options
      options = property_config[:validation_message].split(', ')
      choices = options.map { |opt| { name: opt.capitalize, value: opt } }
      choices << { name: "Skip (leave empty)", value: nil } unless required
      
      select_text = required ? "#{prompt_text}:" : "#{prompt_text} (optional):"
      begin
        return @prompt.select(
          select_text,
          choices,
          help: description,
          cycle: true
        )
      rescue TTY::Reader::InputInterrupt
        # Handle Ctrl+C gracefully during selection
        graceful_shutdown
      end
    else
      # Text input
      loop do
        # Include description in the prompt text instead of using q.help
        ask_text = required ? "#{prompt_text}:" : "#{prompt_text} (optional):"
        if description && description != property_name.to_s.humanize
          ask_text = "#{ask_text}\n  #{description.colorize(:blue)}"
        end
        
        begin
          input = @prompt.ask(ask_text) do |q|
            q.required required
            q.default(default.is_a?(Proc) ? default.call : default) if default
            q.modify :strip
          end
        rescue TTY::Reader::InputInterrupt
          # Handle Ctrl+C gracefully during text input
          graceful_shutdown
        end
        
        # Validate input if validator present
        if validate && input && !validate_value(input, validate)
          show_notification("❌ Invalid input. #{property_config[:validation_message]}", :red)
          next
        end
        
        return convert_input(input, property_name)
      end
    end
  rescue TTY::Reader::InputInterrupt
    return nil
  end

  def prompt_for_property(message_class, property_name)
    property_config = get_property_config(message_class, property_name)
    
    description = property_config[:description] || property_name.to_s.humanize
    required = property_config[:required] || false
    validate = property_config[:validate]
    default = property_config[:default]
    
    # Build prompt with clear required indicator
    prompt = property_name.to_s.humanize.green
    if required
      prompt += " (REQUIRED)".red
    else
      prompt += " (optional)".gray
    end
    
    prompt += " - #{description}".blue if description != property_name.to_s.humanize
    
    if validate.is_a?(Proc) && property_config[:validation_message]
      prompt += "\n  Valid options: #{property_config[:validation_message]}".yellow
    end
    
    if default
      default_val = default.is_a?(Proc) ? default.call : default
      prompt += "\n  Default: #{default_val}".gray
    end
    
    prompt += ":"
    puts prompt
    
    loop do
      print "  > "
      input = gets.chomp.strip
      
      # Handle empty input
      if input.empty?
        if default
          return default.is_a?(Proc) ? default.call : default
        elsif !required
          return nil
        else
          puts "This field is required. Please enter a value.".red
          next
        end
      end
      
      # Convert input based on expected type
      value = convert_input(input, property_name)
      
      # Validate input
      if validate && !validate_value(value, validate)
        puts "Invalid input. #{property_config[:validation_message]}".red
        next
      end
      
      return value
    end
  end

  def get_property_config(message_class, property_name)
    config = {}
    
    # Try to get property configuration from SmartMessage class definition
    begin
      # Check if the message class has property requirements defined
      if message_class.respond_to?(:properties) && message_class.properties.include?(property_name)
        # Try to access the property definition through Hashie::Dash
        if message_class.respond_to?(:property_defaults)
          property_defaults = message_class.property_defaults
          if property_defaults && property_defaults[property_name]
            config[:default] = property_defaults[property_name]
          end
        end
        
        # Check required properties through Hashie::Dash
        if message_class.respond_to?(:required_properties)
          required_props = message_class.required_properties
          config[:required] = required_props.include?(property_name)
        end
      end
      
      # Check if class has property descriptions
      if message_class.respond_to?(:property_descriptions)
        descriptions = message_class.property_descriptions
        config[:description] = descriptions[property_name] if descriptions && descriptions[property_name]
      end
    rescue => e
      logger.debug("Error extracting property config for #{property_name}: #{e.message}")
    end
    
    # Fallback configurations for known message types and properties
    case message_class.name
    when /Emergency911Message/
      case property_name.to_s
      when 'caller_location'
        config[:required] = true
        config[:description] = 'Location where incident is occurring (address or landmark)'
      when 'emergency_type'
        config[:required] = true
        config[:validate] = ->(v) { %w[fire medical crime accident hazmat rescue water_emergency animal_emergency infrastructure_emergency transportation_emergency environmental_emergency parks_emergency sanitation_emergency other].include?(v) }
        config[:validation_message] = 'fire, medical, crime, accident, hazmat, rescue, water_emergency, animal_emergency, infrastructure_emergency, transportation_emergency, environmental_emergency, parks_emergency, sanitation_emergency, other'
      when 'description'
        config[:required] = true
        config[:description] = 'Detailed description of what you observed'
      end
      
    when /SilentAlarmMessage/
      case property_name.to_s
      when 'bank_name'
        config[:required] = true
        config[:description] = "Official name of the bank triggering the alarm (e.g., 'First National Bank')"
      when 'location'
        config[:required] = true
        config[:description] = 'Physical address of the bank location where alarm was triggered'
      when 'alarm_type'
        config[:required] = true
        config[:validate] = ->(v) { %w[robbery vault_breach suspicious_activity].include?(v) }
        config[:validation_message] = 'robbery, vault_breach, suspicious_activity'
        config[:description] = 'Type of security incident detected. Valid values: robbery, vault_breach, suspicious_activity'
      when 'timestamp'
        config[:required] = true
        config[:description] = 'Exact time when the alarm was triggered (YYYY-MM-DD HH:MM:SS format)'
      when 'severity'
        config[:required] = true
        config[:validate] = ->(v) { %w[low medium high critical].include?(v) }
        config[:validation_message] = 'low, medium, high, critical'
        config[:description] = 'Urgency level of the security threat. Valid values: low, medium, high, critical'
      when 'details'
        config[:description] = 'Additional descriptive information about the security incident and current situation'
      end
    end
    
    # Common property configurations
    case property_name.to_s
    when 'severity'
      config[:validate] ||= ->(v) { %w[critical high medium low].include?(v) }
      config[:validation_message] ||= 'critical, high, medium, low'
    when 'injuries_reported', 'fire_involved', 'weapons_involved', 'suspects_on_scene'
      # Boolean fields - no special config needed
    when 'call_received_at', 'timestamp'
      config[:default] ||= -> { Time.now.iso8601 }
    end
    
    config
  end

  def convert_input(input, property_name)
    # Handle nil or empty input
    return nil if input.nil? || input.to_s.strip.empty?
    
    # Convert boolean-like inputs
    if %w[injuries_reported fire_involved weapons_involved suspects_on_scene].include?(property_name.to_s)
      return true if %w[true yes y 1].include?(input.to_s.downcase)
      return false if %w[false no n 0].include?(input.to_s.downcase)
    end
    
    # Convert numeric inputs
    if property_name.to_s.include?('number') || property_name.to_s.include?('count')
      input_str = input.to_s
      return input_str.to_i if input_str.match?(/^\d+$/)
    end
    
    input
  end

  def validate_value(value, validator)
    # Handle nil values gracefully
    return false if value.nil? && validator.is_a?(Proc)
    return true if value.nil? && !validator.is_a?(Proc)  # Allow nil for non-proc validators
    
    case validator
    when Proc
      validator.call(value)
    when Regexp
      # Ensure we have a string to match against
      validator.match?(value.to_s)
    when Array
      validator.include?(value)
    else
      true
    end
  rescue => e
    logger.debug("Validation error: #{e.message}") if respond_to?(:logger)
    false
  end

  def confirm_and_publish_tui(message)
    return unless TTY_AVAILABLE
    
    clear_screen
    
    logger.info("Displaying TUI tip summary for confirmation - Session: #{@tip_session_id}")
    
    # Create summary content
    summary_lines = []
    message.to_h.each do |key, value|
      next if key == :_sm_header
      next if value.nil? || value.to_s.empty?
      summary_lines << "#{key.to_s.humanize}: #{value}"
    end
    
    # Display summary in a box
    safe_width = [@screen_width - 8, 70].min
    summary_box = TTY::Box.frame(
      width: safe_width,
      align: :left,
      padding: [1, 2],
      style: {
        fg: :bright_white,
        border: {
          fg: :yellow,
          type: :thick
        }
      },
      title: { top_left: "📋 TIP SUMMARY" }
    ) { summary_lines.join("\n") }
    
    puts summary_box
    puts
    
    # Confirmation prompt
    begin
      confirmed = @prompt.yes?("🚨 Submit this anonymous tip to Emergency Dispatch?") do |q|
        q.default false
      end
    rescue TTY::Reader::InputInterrupt
      # Handle Ctrl+C gracefully during confirmation
      graceful_shutdown
    end
    
    logger.debug("User TUI confirmation response: #{confirmed} - Session: #{@tip_session_id}")
    
    if confirmed
      logger.info("User confirmed tip submission via TUI - Session: #{@tip_session_id}")
      
      # Show publishing spinner
      spinner = TTY::Spinner.new("[:spinner] Submitting tip to Emergency Dispatch...", format: :dots)
      spinner.auto_spin
      
      begin
        # Log message content for audit trail (sanitized)
        message_summary = message.to_h.reject { |k, v| k == :_sm_header || v.nil? || v.to_s.empty? }
        sanitized_summary = sanitize_message_for_logging(message_summary)
        logger.info("Publishing anonymous tip - Session: #{@tip_session_id}, Content: #{sanitized_summary}")
        
        message.publish
        
        spinner.success("✅ Success!")
        logger.info("Anonymous tip published successfully - Session: #{@tip_session_id}")
        
        # Success message with shorter, properly sized text
        success_box = TTY::Box.frame(
          width: [@screen_width - 8, 60].min,
          height: 7,
          align: :center,
          padding: [1, 2],
          style: {
            fg: :bright_green,
            border: {
              fg: :green,
              type: :thick
            }
          }
        ) do
          [
            "🎉 TIP SUBMITTED SUCCESSFULLY! 🎉",
            "",
            "Forwarded to Emergency Dispatch",
            "",
            "Tip ID: #{@tip_session_id}"
          ].join("\n")
        end
        
        puts success_box
        
        begin
          @prompt.keypress("\nPress any key to continue...", keys: [:return, :space, :escape, :enter])
        rescue TTY::Reader::InputInterrupt
          # Handle Ctrl+C gracefully during keypress
          graceful_shutdown
        end
        
      rescue => e
        spinner.error("❌ Failed!")
        
        logger.error("Error publishing anonymous tip for session #{@tip_session_id}: #{e.class.name} - #{e.message}")
        logger.debug("Publish error backtrace: #{e.backtrace.join("\n")}")
        
        show_notification("❌ Error submitting tip: #{e.message}", :red)
        show_notification("Please try again or contact dispatch directly", :yellow)
      end
    else
      logger.info("User cancelled tip submission via TUI - Session: #{@tip_session_id}")
      show_notification("🛡️  Tip cancelled. Your anonymity is protected.", :yellow)
    end
  end

  def confirm_and_publish(message)
    puts ""
    puts "─" * 40
    puts "TIP SUMMARY".bold.yellow
    puts "─" * 40
    
    logger.info("Displaying tip summary for confirmation - Session: #{@tip_session_id}")
    
    message.to_h.each do |key, value|
      next if key == :_sm_header
      next if value.nil? || value.to_s.empty?
      puts "#{key}: #{value}".cyan
    end
    
    puts ""
    print "Submit this anonymous tip? (y/n): "
    response = gets.chomp.downcase
    
    logger.debug("User confirmation response: #{response} - Session: #{@tip_session_id}")
    
    if %w[y yes].include?(response)
      logger.info("User confirmed tip submission - Session: #{@tip_session_id}")
      
      begin
        # Log message content for audit trail (sanitized)
        message_summary = message.to_h.reject { |k, v| k == :_sm_header || v.nil? || v.to_s.empty? }
        sanitized_summary = sanitize_message_for_logging(message_summary)
        logger.info("Publishing anonymous tip - Session: #{@tip_session_id}, Content: #{sanitized_summary}")
        
        message.publish
        
        puts ""
        puts "✓ Anonymous tip submitted successfully!".green.bold
        puts "Your tip has been forwarded to Emergency Dispatch.".blue
        puts "Tip Reference: #{@tip_session_id}".gray
        
        logger.info("Anonymous tip published successfully - Session: #{@tip_session_id}")
        
      rescue => e
        puts ""
        puts "✗ Error submitting tip: #{e.message}".red
        puts "Please try again or contact dispatch directly.".yellow
        
        logger.error("Error publishing anonymous tip for session #{@tip_session_id}: #{e.class.name} - #{e.message}")
        logger.debug("Publish error backtrace: #{e.backtrace.join("\n")}")
      end
    else
      puts "Tip cancelled.".yellow
      logger.info("User cancelled tip submission - Session: #{@tip_session_id}")
    end
  end

  def continue_tui?
    return false unless TTY_AVAILABLE
    
    begin
      will_continue = @prompt.yes?("🔄 Submit another anonymous tip?") do |q|
        q.default false
      end
    rescue TTY::Reader::InputInterrupt
      # Handle Ctrl+C gracefully during continue prompt
      graceful_shutdown
    end
    
    logger.debug("User TUI continue response: #{will_continue} - Session: #{@tip_session_id}")
    will_continue
  end

  def continue?
    puts ""
    print "Submit another anonymous tip? (y/n): "
    response = gets.chomp.downcase
    
    will_continue = %w[y yes].include?(response)
    logger.debug("User continue response: #{response} (#{will_continue}) - Session: #{@tip_session_id}")
    
    will_continue
  end

  # Sanitize sensitive information for logging while preserving audit trail
  def sanitize_for_logging(property_name, value)
    # Don't log full addresses, just indicate presence
    if property_name.to_s.include?('location') || property_name.to_s.include?('address')
      value.to_s.length > 0 ? "<ADDRESS_PROVIDED>" : "<NO_ADDRESS>"
    # Don't log phone numbers
    elsif property_name.to_s.include?('phone')
      value.to_s.length > 0 ? "<PHONE_PROVIDED>" : "<NO_PHONE>"
    # Don't log caller names
    elsif property_name.to_s.include?('caller_name') || property_name.to_s.include?('name')
      value.to_s.length > 0 ? "<NAME_PROVIDED>" : "<NO_NAME>"
    # Log other properties normally but truncate if too long
    else
      value.to_s.length > 100 ? "#{value.to_s[0..97]}..." : value
    end
  end

  # Sanitize entire message for logging
  def sanitize_message_for_logging(message_hash)
    sanitized = {}
    message_hash.each do |key, value|
      sanitized[key] = sanitize_for_logging(key, value)
    end
    sanitized.to_s
  end
end

# String humanization helper
class String
  def humanize
    self.gsub('_', ' ').split.map(&:capitalize).join(' ')
  end
end

if __FILE__ == $0
  AnonymousTipLine.new.run
end