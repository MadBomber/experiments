#!/usr/bin/env ruby
# experiments/spinner/multi_spinners.rb
#
# Some of the features in tty-spinner listed
# in its README file are not present in the code.
# for example the `log` method is not present.

require 'tty-spinner'

spinner_names = TTY::Formats::FORMATS.keys


print "\nSpinner Names: "
puts spinner_names.join(", ")
puts "Count: #{spinner_names.length}"
puts


def multi_spinners(names)
  multi_spinner = TTY::Spinner::Multi.new("[:spinner] Doing Stuff in Threads")

  names.each do |a_name|
    multi_spinner.register(
                            "[:spinner] #{a_name}",
                            format: a_name.to_sym
                          ) do |sp| 
      sleep(20)
      rand(2).zero? ? sp.error("problem") : sp.success("Ok") 
    end
  end

  # None of those tasks get started until we
  # start the top-level spinner.
  multi_spinner.auto_spin
end


spinner_names.each_slice(10) do |a_slice|
  puts "="*64
  multi_spinners(a_slice)
  sleep 2
end

