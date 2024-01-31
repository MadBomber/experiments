#!/usr/bin/env ruby

# Ruby/ProgressBar is a flexible text progress bar 
# library for providing user feedback during potential 
# long operations.
#
# This pattern provides for status messages to the terminal
# as well as to a log file.

require 'ruby-progressbar'  

def fake_task(record_id)
  sleep 0.5
  "Record #{record_id} #{record_id.even? ? 'failure' : 'successful'}"
end

######################################
## Utility Screen Cursor manipulations
##
## Why not use the gem `tty-cursor` ??
##
## Because it does not always work the
## the way it is supposed to.

def go_to_top
  print "\e[H"
end

def clear_from_cursor_to_end_of_screen
  print "\e[J"
end

def clear_screen
  go_to_top
  clear_from_cursor_to_end_of_screen
end

def clear_to_eol
  print "\x1b[K"
end

# n is number of lines to scroll
def scroll_up(n=1)
  print "\e[#{n}S"  
end

def save_cursor
  print "\e[s"
end

def restore_cursor
  print "\e[u"
end

###################################
## Main

def status(message)
  unless STDOUT.isatty
    puts message
    return
  end

  save_cursor
  print "#{message}"
  # STDOUT.flush
  clear_to_eol
  scroll_up
  restore_cursor
end


total_count = 15

progressbar = ProgressBar.create(
    title: 'Records',
    total: total_count,
    format: '%t: [%B] %c/%C %j%% %e',
    output: STDERR
  )

total_count.times do |x|
  status fake_task(x)
  progressbar.increment
end

progressbar.finish

puts "done."
