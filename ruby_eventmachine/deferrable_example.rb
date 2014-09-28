#!/bin/env ruby
require 'rubygems'

# $eventmachine_library = :pure_ruby  ## If c++ version is available it will be the default

require 'eventmachine'

puts "EM.library_type: #{EM.library_type}"

class MyClass
  include EM::Deferrable

  def print_value x
    puts "MyClass instance received #{x}"
  end
end

EM.run {
  df = MyClass.new
  df.callback {|x|
    df.print_value(x)
    EM.stop
  }

  EM::Timer.new(2) {
    df.set_deferred_status :succeeded, 100
  }
}


