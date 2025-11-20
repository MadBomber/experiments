#!/usr/bin/env ruby
# stream_stdin_sysread.rb

require "debug_me"
include DebugMe

require "io/console"
require "timeout_block"

# Set the terminal to raw mode
def set_raw_mode
  system("stty raw")
end

# Restore terminal mode
def unset_raw_mode
  system("stty -raw")
end

alias :restore_terminal :unset_raw_mode

def get_some_input(stdin_stream)
  if IO.select([stdin_stream], nil, nil, 10)
    return stdin_stream.sysread(1000)
  end
end


begin
  set_raw_mode
  print "Type or say something: "

  result = ""

  IO.open(STDIN.fileno) do |stdin_stream|
    loop do
      input = timeout_block(5) { get_some_input(stdin_stream) }
      break if input.nil?
      print input
      result << input
    
    rescue EOFError
      break
    
    rescue Errno::EAGAIN
      next
    end
  end

  unset_raw_mode

  puts
  puts "Result: #{result}"
  puts

rescue Interrupt
  puts "\nReceived interrupt signal (Control-C). Exiting gracefully."

ensure
  restore_terminal # Ensure we always restore the terminal settings
end

__END__


  IO.open(STDIN.fileno) do |stdin_stream|
    loop do
      if IO.select([stdin_stream], nil, nil, 0.5)
        begin
          input = stdin_stream.sysread(1000)
          break if input.nil?
          puts input
          result << input
        rescue EOFError
          break
        rescue Errno::EAGAIN
          next
        end
      end

      # Optional: To exit the loop (for example, on Ctrl+C)
      break if $stdin&.eof? ||
               input&.include?("\n")
    end
  end




  The `stty raw` command is used to configure the terminal to operate in "raw" mode. In raw
  mode, the terminal input behaves differently compared to the normal (or "cooked") mode. Here’s
  what `stty raw` does:

  ### Effects of `stty raw`:

  1. **Immediate Input**:
  - Characters typed by the user are made immediately available to the program without being
  buffered. This means that input is sent to the application one character at a time, rather
  than waiting for the Enter key to be pressed.

  2. **No Line Editing**:
  - The standard line-editing features (like backspace, arrow keys, etc.) are disabled. Input is
  received exactly as typed without any modifications.

  3. **No Echo**:
  - Input characters are typically not echoed back to the terminal. This means that when a
  character is typed, it won’t be visible to the user unless manually printed by the
  application.

  4. **Special Control Characters**:
  - Special key combinations, such as Ctrl+C (which typically sends an interrupt signal) and
  Ctrl+Z (which would suspend the process), might not behave as they normally would. This can be
  useful for applications that need to handle input more directly, such as text editors or
  games.

  5. **Raw Mode as a Setup for Applications**:
  - Developers often enable raw mode so that they can handle keyboard input more directly,
  providing customized behavior that is not available in the default cooked mode.

  ### Example Scenario:

  - When developing a command-line application that requires real-time user interaction—like a
  multiplayer game or a terminal-based text editor—you would invoke `stty raw` before starting
  your application. This allows your application to process each keystroke instantly and
  implement custom handling for different keys.

  ### Important Note:

  - After you're done with your application or when you want to return to normal terminal
  behavior, it's good practice to run `stty -raw` to switch back to the normal cooked mode. This
  ensures that the terminal input behaves as expected for everyday command-line operations.

  ### Summary:

  In summary, `stty raw` sets the terminal to raw mode, providing immediate access to user input
  without typical buffering or editing features. It's particularly useful for applications that
  require real-time input handling.
