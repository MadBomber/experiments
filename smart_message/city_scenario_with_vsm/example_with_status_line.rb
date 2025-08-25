#!/usr/bin/env ruby

require_relative 'common/status_line'

class MyProgram
  include Common::StatusLine

  def run
    status_line("Starting MyProgram...")
    sleep(1)

    20.times do |i|
      # Regular output - will scroll normally
      puts "Processing item #{i + 1}"

      # Update the status line (stays fixed at bottom)
      status_line("Running: Processing item #{i + 1} of 20")

      sleep(0.1)
    end

    status_line("Done! Press Enter to exit.")
    STDIN.gets
    restore_terminal
  end
end

# Run the program
if __FILE__ == $0
  program = MyProgram.new
  program.run
end