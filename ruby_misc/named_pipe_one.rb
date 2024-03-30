#!/usr/bin/env ruby
# named_pipe_one.rb
#
# Example:
#   ./named_pipe_one.rb & # put into background
#   ./named_pipe_two.rb
#


# writer.rb
require "tmpdir"

fifo_path = File.join(Dir.tmpdir, "my_fifo")

# Create named pipe unless it already exists
File.mkfifo(fifo_path) unless File.exist?(fifo_path)

# Open and write to the FIFO
File.open(fifo_path, "w") do |fifo|
  fifo.puts "Hello from writer"
end
