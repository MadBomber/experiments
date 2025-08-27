#!/usr/bin/env ruby

require 'tty-cursor'
require 'tty-screen'
require 'tty-reader'
require 'tty-box'
require 'pastel'
require 'io/console'

class AdvancedTUI
  attr_reader :output_buffer, :input_buffer, :status_text, :info_text
  
  def initialize
    @cursor = TTY::Cursor
    @pastel = Pastel.new
    @reader = TTY::Reader.new(interrupt: :signal)
    
    @screen_width = TTY::Screen.width
    @screen_height = TTY::Screen.height
    
    # Define regions
    @status_lines = 2  # Bottom 2 lines for status
    @input_lines = 4   # Default 4 lines for input above status
    @input_lines_max = @screen_height - @status_lines - 6  # Leave room for output (minimum 3 lines) and borders
    @input_scroll_offset = 0  # For scrolling within input area
    @output_start = 1
    @output_end = @screen_height - @status_lines - @input_lines - 1
    
    # Fixed status area position - never changes
    @status_area_top = @screen_height - @status_lines - 1
    
    # Buffers
    @output_buffer = []
    @input_buffer = []
    @current_input_line = 0
    @cursor_x = 0
    @cursor_y = 0
    @input_text = [""]  # Array of strings for multi-line input
    
    # Status and info
    @status_text = "Ready"
    @info_text = "Arrows: navigate, Enter: submit, Shift+Enter: new line, Home/End: line start/end, Del: delete, ESC: quit"
    
    # Initialize screen
    clear_screen
    draw_borders
    update_status
  end
  
  def clear_screen
    print @cursor.clear_screen
    print @cursor.move_to(0, 0)
  end
  
  def calculate_current_input_lines
    # Dynamic input area size based on actual content, but never exceed maximum
    actual_lines = [@input_text.length, @input_lines].max
    # Ensure we never expand beyond the safe limit that preserves status area
    [@input_lines_max, actual_lines].min
  end
  
  def update_layout
    current_input_lines = calculate_current_input_lines
    @output_end = @screen_height - @status_lines - current_input_lines - 1
  end
  
  def draw_borders
    update_layout
    current_input_lines = calculate_current_input_lines
    
    # Clear screen first
    clear_screen
    
    # Draw output area border
    output_box = TTY::Box.frame(
      left: 0,
      top: 0,
      width: @screen_width,
      height: @output_end + 1,
      title: { top_left: " Output " },
      border: :light,
      style: { fg: :cyan }
    )
    print output_box
    
    # Draw input area border (dynamic size, but never overlapping status)
    input_top = @output_end + 1
    input_height = current_input_lines + 2
    
    # Ensure input area never overlaps with status area
    max_input_bottom = @status_area_top - 1
    if input_top + input_height > max_input_bottom
      input_height = max_input_bottom - input_top
    end
    
    input_box = TTY::Box.frame(
      left: 0,
      top: input_top,
      width: @screen_width,
      height: input_height,
      title: { top_left: " Input (↑↓←→ to navigate, Enter to submit, expands as needed) " },
      border: :thick,
      style: { fg: :yellow }
    )
    print input_box
    
    # Draw status area border (always at fixed position)
    status_box = TTY::Box.frame(
      left: 0,
      top: @status_area_top,
      width: @screen_width,
      height: @status_lines + 1,
      title: { top_left: " Status " },
      border: :light,
      style: { fg: :green }
    )
    print status_box
  end
  
  def add_output(text)
    # Split text into lines that fit the width
    max_width = @screen_width - 4  # Account for borders
    
    text.to_s.split("\n").each do |line|
      if line.length > max_width
        # Wrap long lines
        line.scan(/.{1,#{max_width}}/).each { |chunk| @output_buffer << chunk }
      else
        @output_buffer << line
      end
    end
    
    # Keep only as many lines as fit in the output area
    max_lines = @output_end - @output_start
    if @output_buffer.length > max_lines
      @output_buffer = @output_buffer.last(max_lines)
    end
    
    refresh_output
  end
  
  def refresh_output
    # Clear the output area
    (@output_start..@output_end - 1).each do |y|
      print @cursor.move_to(2, y + 1)
      print " " * (@screen_width - 4)
    end
    
    # Display the buffer
    @output_buffer.each_with_index do |line, i|
      break if i >= @output_end - @output_start
      print @cursor.move_to(2, @output_start + i + 1)
      print line[0..(@screen_width - 5)]
    end
  end
  
  def refresh_input
    update_layout
    current_input_lines = calculate_current_input_lines
    
    # Calculate scroll offset if we have more content than can be displayed
    if @input_text.length > current_input_lines
      # Ensure cursor is visible
      if @cursor_y >= @input_scroll_offset + current_input_lines
        @input_scroll_offset = @cursor_y - current_input_lines + 1
      elsif @cursor_y < @input_scroll_offset
        @input_scroll_offset = @cursor_y
      end
      
      # Clamp scroll offset to valid range
      max_scroll = [@input_text.length - current_input_lines, 0].max
      @input_scroll_offset = [[@input_scroll_offset, 0].max, max_scroll].min
    else
      @input_scroll_offset = 0
    end
    
    # Clear the input area
    (0...current_input_lines).each do |i|
      print @cursor.move_to(2, @output_end + 2 + i)
      print " " * (@screen_width - 4)
    end
    
    # Display the input text with scrolling
    (0...current_input_lines).each do |display_line|
      input_line_index = display_line + @input_scroll_offset
      break if input_line_index >= @input_text.length
      
      line = @input_text[input_line_index] || ""
      print @cursor.move_to(2, @output_end + 2 + display_line)
      
      if input_line_index == @cursor_y
        # Highlight current line
        print @pastel.on_blue(line.ljust(@screen_width - 4)[0..(@screen_width - 5)])
      else
        print line[0..(@screen_width - 5)]
      end
    end
    
    # Position cursor (adjust for scrolling)
    display_y = @cursor_y - @input_scroll_offset
    if display_y >= 0 && display_y < current_input_lines
      print @cursor.move_to(2 + @cursor_x, @output_end + 2 + display_y)
      print @cursor.show
    end
  end
  
  def update_status(status = nil)
    @status_text = status if status
    
    # Always update status at fixed position
    # Update status line
    print @cursor.move_to(2, @status_area_top + 1)
    print @pastel.green(@status_text.ljust(@screen_width - 4)[0..(@screen_width - 5)])
    
    # Update info line  
    print @cursor.move_to(2, @status_area_top + 2)
    print @pastel.cyan(@info_text.ljust(@screen_width - 4)[0..(@screen_width - 5)])
    
    refresh_input  # Return cursor to input area
  end
  
  def handle_auto_wrap
    max_width = @screen_width - 6  # Account for borders and padding
    current_line = @input_text[@cursor_y]
    
    # Only wrap if we've exceeded the line width
    if current_line.length >= max_width
      # Find the last space before the wrap point to break at word boundary
      last_space_pos = current_line.rindex(' ', max_width - 1)
      
      if last_space_pos && last_space_pos > max_width * 0.3  # Don't wrap too early
        # Split at word boundary
        current_text = current_line[0...last_space_pos]
        wrapped_text = current_line[last_space_pos + 1..-1] || ""
        
        # Adjust cursor position if it's in the wrapped portion
        if @cursor_x > last_space_pos
          new_cursor_x = @cursor_x - last_space_pos - 1
        else
          new_cursor_x = 0  # Start of wrapped line
        end
      else
        # No good word boundary found, split at max width
        current_text = current_line[0...max_width]
        wrapped_text = current_line[max_width..-1] || ""
        
        # Adjust cursor position
        if @cursor_x >= max_width
          new_cursor_x = @cursor_x - max_width
        else
          new_cursor_x = 0
        end
      end
      
      # Always allow wrapping - input area will expand as needed
      @input_text[@cursor_y] = current_text
      
      # Insert new line or use existing one
      if @cursor_y + 1 < @input_text.length
        @input_text[@cursor_y + 1] = wrapped_text + (@input_text[@cursor_y + 1] || "")
      else
        @input_text.insert(@cursor_y + 1, wrapped_text)
      end
      
      # Move cursor to appropriate position on wrapped line
      @cursor_y += 1
      @cursor_x = new_cursor_x
      
      # Redraw borders if input area expanded
      if calculate_current_input_lines > @input_lines
        draw_borders
        refresh_output
        update_status()  # Restore status content
      end
    end
  end

  def handle_input
    loop do
      refresh_input
      
      key = @reader.read_keypress
      
      case key
      when "\e[A", :up  # Up arrow
        if @cursor_y > 0
          @cursor_y -= 1
          # Keep cursor at same x position if possible, otherwise move to end of line
          @cursor_x = [@cursor_x, @input_text[@cursor_y].length].min
          update_status("Cursor moved up")
        end
        
      when "\e[B", :down  # Down arrow
        if @cursor_y < @input_text.length - 1
          @cursor_y += 1
          # Keep cursor at same x position if possible, otherwise move to end of line
          @cursor_x = [@cursor_x, @input_text[@cursor_y].length].min
          update_status("Cursor moved down")
        end
        
      when "\e[D", :left  # Left arrow
        if @cursor_x > 0
          # Move left within current line
          @cursor_x -= 1
        elsif @cursor_y > 0
          # Move to end of previous line
          @cursor_y -= 1
          @cursor_x = @input_text[@cursor_y].length
        end
        update_status("Cursor moved left")
        
      when "\e[C", :right  # Right arrow
        if @cursor_x < @input_text[@cursor_y].length
          # Move right within current line
          @cursor_x += 1
        elsif @cursor_y < @input_text.length - 1
          # Move to beginning of next line
          @cursor_y += 1
          @cursor_x = 0
        end
        update_status("Cursor moved right")
        
      when "\r", "\n"  # Enter
        if @reader.read_keypress(nonblock: true) == "\n"  # Shift+Enter detection
          # Add new line - input area will expand as needed
          current_line = @input_text[@cursor_y]
          before = current_line[0...@cursor_x]
          after = current_line[@cursor_x..-1] || ""
          
          @input_text[@cursor_y] = before
          @input_text.insert(@cursor_y + 1, after)
          @cursor_y += 1
          @cursor_x = 0
          
          # Redraw borders if input area expanded
          if calculate_current_input_lines > @input_lines
            draw_borders
            refresh_output
            update_status()  # Restore status content
          end
          
          update_status("New line added")
        else
          # Submit input
          submit_input
        end
        
      when "\x7F", "\b", :backspace  # Backspace
        if @cursor_x > 0
          # Delete character before cursor
          @input_text[@cursor_y][@cursor_x - 1, 1] = ""
          @cursor_x -= 1
        elsif @cursor_y > 0
          # Join current line with previous line
          prev_line_length = @input_text[@cursor_y - 1].length
          @input_text[@cursor_y - 1] += @input_text[@cursor_y]
          @input_text.delete_at(@cursor_y)
          @cursor_y -= 1
          @cursor_x = prev_line_length
          
          # Redraw if input area shrunk
          new_input_lines = calculate_current_input_lines
          if new_input_lines < [@input_text.length + 1, @input_lines].max
            draw_borders
            refresh_output
            update_status()
          end
        end
        update_status("Character deleted")
        
      when "\e[3~", :delete  # Delete key
        if @cursor_x < @input_text[@cursor_y].length
          # Delete character at cursor position
          @input_text[@cursor_y][@cursor_x, 1] = ""
        elsif @cursor_y < @input_text.length - 1
          # Join next line with current line
          @input_text[@cursor_y] += @input_text[@cursor_y + 1]
          @input_text.delete_at(@cursor_y + 1)
          
          # Redraw if input area shrunk
          new_input_lines = calculate_current_input_lines
          if new_input_lines < [@input_text.length + 1, @input_lines].max
            draw_borders
            refresh_output
            update_status()
          end
        end
        update_status("Character deleted forward")
        
      when "\e[H", "\e[1~", :home  # Home key
        @cursor_x = 0
        update_status("Moved to start of line")
        
      when "\e[F", "\e[4~", :end  # End key
        @cursor_x = @input_text[@cursor_y].length
        update_status("Moved to end of line")
        
      when :escape, "\e"
        update_status("Exiting...")
        return :exit
        
      when String
        if key.length == 1 && key.ord >= 32 && key.ord < 127
          # Insert character at cursor position
          @input_text[@cursor_y].insert(@cursor_x, key)
          @cursor_x += 1
          
          # Check for auto word-wrap
          handle_auto_wrap
          
          update_status("Typing...")
        else
          # Debug: show unknown key codes
          update_status("Unknown key: #{key.inspect} (#{key.bytes.map{|b| b.to_s(16)}.join(' ')})")
        end
      end
    end
  end
  
  def submit_input
    input = @input_text.join("\n").strip
    
    unless input.empty?
      add_output(@pastel.yellow("> #{input}"))
      update_status("Input submitted: #{input[0..30]}#{input.length > 30 ? '...' : ''}")
      
      # Process the input (this is where you'd add your logic)
      result = process_command(input)
      add_output(result)
    end
    
    # Clear input and reset to normal size
    @input_text = [""]
    @cursor_x = 0
    @cursor_y = 0
    @input_scroll_offset = 0
    
    # Redraw with normal size and restore status
    draw_borders
    refresh_output
    update_status()  # Restore status content
    refresh_input
  end
  
  def process_command(input)
    case input.downcase
    when "help"
      @pastel.green("Available commands:\n") +
      "  help     - Show this help\n" +
      "  time     - Show current time\n" +
      "  clear    - Clear output\n" +
      "  test     - Run test output\n" +
      "  exit     - Exit the program"
      
    when "time"
      @pastel.blue("Current time: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}")
      
    when "clear"
      @output_buffer.clear
      refresh_output
      @pastel.green("Output cleared")
      
    when "test"
      test_output
      
    when "exit", "quit"
      exit(0)
      
    else
      @pastel.red("Unknown command: #{input}\nType 'help' for available commands")
    end
  end
  
  def test_output
    results = []
    results << @pastel.cyan("Running test sequence...")
    
    10.times do |i|
      results << "Test line #{i + 1}: #{('A'..'Z').to_a.sample(20).join}"
    end
    
    results << @pastel.green("Test complete!")
    results.join("\n")
  end
  
  def run
    add_output(@pastel.green.bold("Advanced TUI Demo"))
    add_output(@pastel.cyan("Type 'help' for available commands"))
    add_output("")
    
    handle_input
    
    clear_screen
    puts "\nGoodbye!"
  end
end

if __FILE__ == $0
  tui = AdvancedTUI.new
  tui.run
end