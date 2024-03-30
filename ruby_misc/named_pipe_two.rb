#!/usr/bin/env ruby
# named_pipe_two.rb
#
# Example:
#   ./named_pipe_one.rb & # put into background
#   ./named_pipe_two.rb
#

# reader.rb
require "tmpdir"

fifo_path = File.join(Dir.tmpdir, "my_fifo")

# Open and read from the FIFO
File.open(fifo_path, "r") do |fifo|
  puts fifo.gets
end
