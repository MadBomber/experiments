#!/usr/bin/env ruby
# experiments/spinner/single_spinner.rb
#
# Some of the features in tty-spinner listed
# in its README file are not present in the code.
# for example the `log` method is not present.

require 'tty-spinner'

def spin_the_tires(
      title:            "Loading ...",
      type_of_spinner:  :bouncing_ball
    )

  spinner = TTY::Spinner.new(
              ":spinner :title ", 
              format: type_of_spinner
            )

  spinner.update(title: title)

  spinner.auto_spin # Automatic animation with default interval

  yield if block_given?

  spinner.stop("Done!") # Stop animation
end


spin_the_tires do
  %w[ one two three four].each do |phase|
    sleep rand(10)+1
    puts "Phase #{phase} complete"
  end
end

