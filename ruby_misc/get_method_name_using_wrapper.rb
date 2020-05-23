#!/usr/bin/env ruby
# get_method_name_using_wrapper.rb

# This is a wrapper method
def hello(method_name_symbol, foo: 'bar')
  puts "Hello #{method_name_symbol} what is foo? #{foo}"
end

# use the wrapper method around another methods definition
hello def world
  puts 'xyzzy'
end, foo: 'baz'

puts "world says #{world}"
