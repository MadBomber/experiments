#!/usr/bin/env ruby
# experiments/spinner/spinner_test.rb
#
# With the exception of "duration" most
# of the major of the concepts work as documented
#
# ALSO the `log` method does not work
#

require 'debug_me'
include DebugMe


require 'tty-spinner'

if false
  debug_me('formats'){[
    'TTY::Formats::FORMATS'
  ]}
end

spinner_names = TTY::Formats::FORMATS.keys


def zero(type_of_spinner, max=3)
  puts "="*65
  puts "== type: #{type_of_spinner}"

  spinner = TTY::Spinner.new("[:spinner] Loading ... ", format: type_of_spinner)

  spinner.auto_spin # Automatic animation with default interval

  sleep(5) # Perform task

  spinner.stop("Done!") # Stop animation
end



def one(type_of_spinner = :pulse_2)
  puts "="*65
  puts "== type: #{type_of_spinner}"

  spinner = TTY::Spinner.new("[:spinner] Loading ... ", format: type_of_spinner)

  spinner.auto_spin # Automatic animation with default interval

  sleep(5) # Perform task

  puts "half way"

  sleep(5)

  spinner.stop("Done!") # Stop animation
end


# How to support multiple parallel spinners in
# a workflow.  Does not support IO to STDOUR or
# to STDERR.
#
def two
  puts "="*65
  
  spinners = TTY::Spinner::Multi.new("[:spinner] top")

  sp1 = spinners.register "[:spinner] one"
  # or sp1 = ::TTY::Spinner.new("[:spinner] one")
  # spinners.register sp1
  sp2 = spinners.register "[:spinner] two"

  sp1.auto_spin
  sp2.auto_spin

  sleep(5) # Perform work

  # Does not support IO to STDOUT or STDERR
  # STDERR.puts
  # STDERR.puts "task 1 is done"
  # STDERR.puts
  # The log method does not work either
  # spinners.log "message to console"
  # sp1.log "message to console"
  # sp2.log "message to console"

  # put a checkmark in place of the spinner
  # and print the string
  sp1.success("(successful)")

  sleep(5)
  # replace spinner with an "x" and
  # print string parameter
  sp2.error("(error)")
end


def two_again
  multi_spinner = TTY::Spinner::Multi.new("[:spinner] Doing Stuff in Threads")

  %w[
    one two three four
  ].each do |a_name|
    multi_spinner.register("[:spinner] #{a_name}") do |sp| 
      sleep(rand(10))
      rand(2).zero? ? sp.error("problem") : sp.success("Ok") 
    end
  end

  # None of those tasks get started until we
  # start the top-level spinner.
  multi_spinner.auto_spin
end


def two_again_again
  spinner = TTY::Spinner.new("[:spinner] making it go sir ...")

  th1 = Thread.new { 20.times { spinner.spin; sleep(0.2) } }
  th2 = Thread.new { 20.times { spinner.spin; sleep(0.2) } }
  th3 = Thread.new { 20.times { spinner.spin; sleep(0.2) } }

  [th1, th2, th3].each(&:join)

  spinner.success "All threads have completed."
end


def three(type_of_spinner=:pulse_2, max=5)
  puts "="*65

  # NOTE: two placeholders 
  #   :spinner is the location where the animation happens
  #   :title is the, um, title
  spinner = TTY::Spinner.new("[:spinner] :title ... ", format: type_of_spinner)
  spinner.update(title: "Loading")

  # saves the starting time
  spinner.start

  counter = 0
  while counter < max do
    spinner.spin
    counter += 1
    sleep 1
  end

  # spinner.pause # pause does not take a param "half way"
  
  puts "Took #{spinner.duration} seconds to go half way"


  # dynamically change the title of a spinner
  spinner.update(title: "Q-three")
  spinner.run { sleep max / 2}
    
  spinner.update(title: "Q-four")
  spinner.run { sleep max / 2}

  # saves the ending time and prints the parameters
  spinner.stop "Done."

  # SMELL: duration only works when spinner object has a defined
  # started_at value.  It looks like stop, run and pause somehow
  # remove the started_at object.

  puts "Took #{spinner.duration} seconds to go all the way"

  # NOTE: `duration` is an incomplete concept that is poorly
  #       documented in inadequately tested.
end


# Supports 3 callabacks :done, :error, :success
# :done event is fired regardless of success or failure
def four(type_of_spinner=:pulse_2, max=5)
  puts "="*65

  spinner = TTY::Spinner.new("[:spinner] Loading ... ", format: type_of_spinner)
  
  # This event is being fired twice.  It happens
  # before the error or success event block is executed
  # and after that block as well.  Guessing that the 
  # second time is at the end of the four method
  #
  spinner.on(:done)     { puts "its over"}
  
  spinner.on(:error)    { STDERR.puts "ERROR: rand() returned a zero"}
  spinner.on(:success)  { puts "completed successfully"}


  spinner.run do
    counter = 0

    while counter < max do
      counter += 1
      # SMELL: does not work
      # spinner.log "#{counter} "
      sleep 1
      if rand(4).zero?
        spinner.error("got zero at #{counter}")
        break
      end
    end

    spinner.success unless counter < max  
  end
end


# This is an example from tty-spinner's repo examples
# folder.  It does not work.  log is undefined
def five
  puts "="*65

  spinner = TTY::Spinner.new("[:spinner] processing...", format: :bouncing_ball)

  10.times do |i|
    spinner.log("[#{i}] Task")
    sleep(1)
    spinner.spin
  end

  spinner.success
end


# The update mathod works in this example
# The difference the use of the ":title" placeholder
# in the constructor parameter.
def six
  spinner = TTY::Spinner.new(":spinner :title", format: :pulse_3)

  spinner.update(title: "task aaaaa")

  20.times { spinner.spin; sleep(0.2) }

  spinner.update(title: "task b")

  20.times { spinner.spin; sleep(0.2) }
end


def seven(type_of_spinner=:pulse_2, max=3)
  puts "="*65
  puts "== type: #{type_of_spinner}"

  spinner = TTY::Spinner.new("[:spinner] Loading ... ", format: type_of_spinner)

  spinner.auto_spin # Automatic animation with default interval

  sleep(5) # Perform task

  puts "1 spinning for #{spinner.duration} seconds."

  sleep(2)

  puts "2 spinning for #{spinner.duration} seconds."

  spinner.pause

  sleep(2)
  puts "3 spinning for #{spinner.duration} seconds."

  spinner.resume

  sleep(2)

  puts "4 spinning for #{spinner.duration} seconds."
  spinner.stop("Done!") # Stop animation

  sleep(2)
  duration = spinner.duration
  
  if duration.nil?
    puts "5 'spinning is not' said yoda."
  else
    puts "5 spinning for #{duration} seconds."
  end
end





if false
  spinner_names.each do |spinner|
    zero(spinner)
  end
end


one(:pulse_1) if false
one(:pulse_2) if false
one(:pulse_3) if false

two if false
two_again if false
two_again_again if false

three if false

four if false

five if false

six if false

seven if true
