#!/usr/bin/env ruby
# fixed_io_pipe_example.rb

reader, writer = IO.pipe

fork do
  reader.close # Close the reader end in the child process that won't use it
  puts "fork one"
  # This child primarily writes, so no need for a 'read' operation here - removing it
  writer.puts "Hello from fork one"
  writer.close
end

fork do
  writer.close # Close the writer end in the child process that won't use it
  puts "fork two"
  puts "fork two reads: #{reader.read}"
  reader.close
end

# Close the parent's unused ends after forking
writer.close
reader.close

puts "waiting"
Process.waitall