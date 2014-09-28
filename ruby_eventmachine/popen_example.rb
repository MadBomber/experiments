#!/bin/env ruby
##########################
## File:  popen_example.rb
#

require 'rubygems'
require 'eventmachine'

module RubyCounter
  def post_init
    # count up to 5
    send_data "5\n"
  end
  def receive_data data
    puts "ruby sent me: #{data}"
  end
  def unbind
    puts "ruby died with exit status: #{get_status.exitstatus}"
    EM.stop
  end
end

EM.run{
  EM.popen("ruby -e' $stdout.sync = true; gets.to_i.times{ |i| puts i+1; sleep 1 } '", RubyCounter)
  EM.system('ls'){ |output,status| puts output if status.exitstatus == 0 }
  EM.system('sh', proc{ |process|
      process.send_data("echo hello\n")
      process.send_data("ps\n")
      process.send_data("exit\n")
    }, proc{ |out,status|
      puts(out)
    }
  )


}

puts "Done."
