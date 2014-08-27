#!/usr/bin/env ruby
###################################
## testing the show method
require "rubygems"
require 'pp'
#require 'lll'
#require "d"

	a = ["bob", :doub, 42.69, {"a"=>"alpha"}]
	b = 2
	c = Time.now

def debug_me( options={:tag => 'DEBUG', :header => true}, &block )
  options = {:tag => options, :header => true} unless 'Hash' == options.class.to_s
  puts "debug_me from #{caller} at #{Time.now}" if options[:header]
  if block_given?
    s = "  #{options[:tag]}:"
    block_value = [ block.call ].flatten.compact
    if block_value.empty?
      block_value = eval('local_variables', block)
      block_value += [ eval('instance_variables', block) ]
      block_value += [ self.class.send('class_variables') ]
      block_value = block_value.flatten.compact
    else
      block_value.map! { |v| v.to_s }
    end
    block_value.each do |v|
      ev = eval(v, block)
      puts "#{s} #{v} -=> #{ev.inspect}"
    end
  end
end

debug_me

puts "="*15
puts 'debug_me'
debug_me{:a}

puts "="*15
puts 'debug_me with an array'
debug_me{[:a, :b]}

puts "="*15
puts 'debug_me with an empty block'
debug_me{}

puts "="*15
puts 'debug_me with an empty block and a tag'
debug_me('INFO'){}

class Foo
  @@baz = 654.321
  attr_accessor :bar
  def initialize
    @bar = 123.456
    puts self.class.send('class_variables')
  end
  def xyzzy
    debug_me(:tag => 'xyzzy'){}
  end
  def yzzyx
    debug_me(:tag => 'yzzyx'){:@bar}
  end
end

puts "="*15
puts 'new Foo'
f=Foo.new

puts "="*15
puts 'class_variables'
puts Foo.class_variables

puts "="*15
puts 'xyzzy'
f.xyzzy

puts "="*15
puts 'yzzyx'
f.yzzyx


debug_me

