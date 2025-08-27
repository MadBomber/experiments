#!/usr/bin/env ruby

require_relative 'advanced_tui'
require 'date'
require 'json'

class ChatDemo < AdvancedTUI
  def initialize
    super
    @username = "User"
    @messages = []
    @commands = {
      'help' => 'Show available commands',
      'name' => 'Change your username',
      'time' => 'Display current time',
      'date' => 'Display current date', 
      'clear' => 'Clear chat history',
      'save' => 'Save chat to file',
      'load' => 'Load chat from file',
      'echo' => 'Echo your message',
      'calc' => 'Simple calculator (e.g., calc 2+2)',
      'lorem' => 'Generate lorem ipsum text',
      'status' => 'Show system status',
      'colors' => 'Show color test',
      'stress' => 'Stress test output scrolling',
      'multi' => 'Test multi-line input',
      'exit' => 'Exit the program'
    }
    
    @info_text = "Commands start with '/', use arrows to navigate, Shift+Enter for new line"
    update_status("Welcome! Type /help for commands")
  end
  
  def process_command(input)
    lines = input.split("\n")
    first_line = lines.first.strip
    
    # Check for commands (start with /)
    if first_line.start_with?('/')
      cmd_parts = first_line[1..-1].split(' ', 2)
      command = cmd_parts[0].downcase
      args = cmd_parts[1] || ""
      
      case command
      when 'help'
        show_help
        
      when 'name'
        change_name(args)
        
      when 'time'
        @pastel.cyan("Current time: #{Time.now.strftime('%H:%M:%S')}")
        
      when 'date'
        @pastel.cyan("Current date: #{Date.today.strftime('%A, %B %d, %Y')}")
        
      when 'clear'
        @output_buffer.clear
        @messages.clear
        refresh_output
        @pastel.green("Chat cleared")
        
      when 'save'
        save_chat(args)
        
      when 'load'
        load_chat(args)
        
      when 'echo'
        @pastel.magenta("Echo: #{args}\n#{lines[1..-1].join("\n") if lines.length > 1}")
        
      when 'calc'
        calculate(args)
        
      when 'lorem'
        generate_lorem
        
      when 'status'
        show_status
        
      when 'colors'
        color_test
        
      when 'stress'
        stress_test
        
      when 'multi'
        multi_line_test(lines)
        
      when 'exit', 'quit'
        exit(0)
        
      else
        @pastel.red("Unknown command: /#{command}\nType /help for available commands")
      end
    else
      # Regular message
      timestamp = Time.now.strftime('%H:%M')
      message = "#{@pastel.blue("[#{timestamp}]")} #{@pastel.green(@username)}: #{input}"
      @messages << { time: timestamp, user: @username, text: input }
      
      # Simulate response
      response = generate_response(input)
      if response
        @messages << { time: Time.now.strftime('%H:%M'), user: 'Bot', text: response }
        message += "\n#{@pastel.blue("[#{Time.now.strftime('%H:%M')}]")} #{@pastel.magenta('Bot')}: #{response}"
      end
      
      message
    end
  end
  
  def show_help
    help_text = @pastel.green.bold("Available Commands:\n")
    help_text += @pastel.cyan("─" * 40 + "\n")
    
    @commands.each do |cmd, desc|
      help_text += @pastel.yellow("/#{cmd.ljust(10)}") + " - #{desc}\n"
    end
    
    help_text += @pastel.cyan("─" * 40 + "\n")
    help_text += "Regular text without '/' is treated as chat message"
    help_text
  end
  
  def change_name(new_name)
    if new_name.empty?
      @pastel.yellow("Usage: /name <new_username>")
    else
      old_name = @username
      @username = new_name.strip
      update_status("Username changed to: #{@username}")
      @pastel.green("Username changed from '#{old_name}' to '#{@username}'")
    end
  end
  
  def calculate(expression)
    begin
      result = eval(expression.gsub(/[^0-9+\-*\/().]/,''))
      @pastel.green("#{expression} = #{result}")
    rescue => e
      @pastel.red("Error in calculation: #{e.message}")
    end
  end
  
  def generate_lorem
    words = %w[lorem ipsum dolor sit amet consectetur adipiscing elit sed do 
               eiusmod tempor incididunt ut labore et dolore magna aliqua]
    
    paragraphs = rand(2..4)
    text = ""
    
    paragraphs.times do |p|
      sentence_count = rand(3..6)
      paragraph = ""
      
      sentence_count.times do
        word_count = rand(8..15)
        sentence = word_count.times.map { words.sample }.join(' ').capitalize + ". "
        paragraph += sentence
      end
      
      text += paragraph + "\n\n"
    end
    
    @pastel.dim(text.strip)
  end
  
  def show_status
    status = @pastel.green.bold("System Status\n")
    status += @pastel.cyan("─" * 30 + "\n")
    status += "Screen: #{@screen_width}x#{@screen_height}\n"
    status += "Output buffer: #{@output_buffer.length} lines\n"
    status += "Messages: #{@messages.length} total\n"
    status += "Input mode: Multi-line (#{@input_lines} lines)\n"
    status += "Username: #{@username}\n"
    status += "Time: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    status
  end
  
  def color_test
    colors = @pastel.red("Red ") + 
             @pastel.green("Green ") +
             @pastel.yellow("Yellow ") +
             @pastel.blue("Blue ") +
             @pastel.magenta("Magenta ") +
             @pastel.cyan("Cyan ") +
             @pastel.white("White\n") +
             @pastel.on_red("BG Red ") +
             @pastel.on_green("BG Green ") +
             @pastel.on_yellow.black("BG Yellow ") +
             @pastel.on_blue("BG Blue ") +
             @pastel.on_magenta("BG Magenta ") +
             @pastel.on_cyan.black("BG Cyan ") +
             @pastel.on_white.black("BG White")
    colors
  end
  
  def stress_test
    update_status("Running stress test...")
    results = []
    
    50.times do |i|
      results << "Line #{i+1}: " + (('A'..'Z').to_a + ('a'..'z').to_a).sample(rand(20..80)).join
    end
    
    update_status("Stress test complete - 50 lines generated")
    results.join("\n")
  end
  
  def multi_line_test(lines)
    text = @pastel.green.bold("Multi-line Input Test\n")
    text += @pastel.cyan("─" * 30 + "\n")
    text += "You entered #{lines.length} line(s):\n\n"
    
    lines.each_with_index do |line, i|
      text += @pastel.yellow("Line #{i+1}: ") + line + "\n"
    end
    
    text += @pastel.cyan("─" * 30 + "\n")
    text += "Total characters: #{lines.join.length}"
    text
  end
  
  def save_chat(filename)
    filename = "chat_#{Time.now.strftime('%Y%m%d_%H%M%S')}.json" if filename.empty?
    
    begin
      File.write(filename, JSON.pretty_generate(@messages))
      @pastel.green("Chat saved to #{filename}")
    rescue => e
      @pastel.red("Error saving chat: #{e.message}")
    end
  end
  
  def load_chat(filename)
    if filename.empty?
      @pastel.yellow("Usage: /load <filename>")
    else
      begin
        data = JSON.parse(File.read(filename))
        @messages = data
        
        # Replay messages to output
        @output_buffer.clear
        data.each do |msg|
          text = "#{@pastel.blue("[#{msg['time']}]")} "
          text += msg['user'] == 'Bot' ? @pastel.magenta(msg['user']) : @pastel.green(msg['user'])
          text += ": #{msg['text']}"
          add_output(text)
        end
        
        @pastel.green("Chat loaded from #{filename} (#{data.length} messages)")
      rescue => e
        @pastel.red("Error loading chat: #{e.message}")
      end
    end
  end
  
  def generate_response(input)
    # Simple bot responses
    case input.downcase
    when /hello|hi|hey/
      ["Hello there!", "Hi! How can I help?", "Hey! Nice to meet you!"].sample
    when /how are you/
      ["I'm doing great, thanks!", "All systems operational!", "Better now that you're here!"].sample
    when /bye|goodbye/
      ["Goodbye!", "See you later!", "Take care!"].sample
    when /thanks|thank you/
      ["You're welcome!", "Happy to help!", "No problem!"].sample
    when /\?$/
      ["That's an interesting question!", "Let me think about that...", "I'm not sure, but I'll try to help!"].sample
    else
      nil  # No response for other inputs
    end
  end
  
  def run
    add_output(@pastel.green.bold("═" * 50))
    add_output(@pastel.green.bold(" " * 15 + "Chat Demo Application"))
    add_output(@pastel.green.bold("═" * 50))
    add_output("")
    add_output(@pastel.cyan("Welcome, #{@username}!"))
    add_output(@pastel.yellow("Type /help for available commands"))
    add_output(@pastel.dim("Regular text is treated as chat messages"))
    add_output("")
    
    handle_input
    
    clear_screen
    puts @pastel.green("\nThank you for using Chat Demo!")
  end
end

if __FILE__ == $0
  app = ChatDemo.new
  app.run
end