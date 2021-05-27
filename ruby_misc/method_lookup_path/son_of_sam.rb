#!/usr/bin/env ruby
# experiments/method_lookup_path/son_of_sam.rb

=begin

  Some people think that when a method of the superclass is called, if it
  calls a method that is defined in both the superclass and the subclass,
  the method from the superclass will be used in place of the method from
  the subclass.

  Billy Boy disproves that thinking by counting: 11, 22, 33

=end

class Sam
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def one; 1; end
  def two; 2; end
  def three; one + two; end
end


class Son < Sam
  def initialize(thing)
    super
  end

  def one
    11
  end

  def two
    20 + super
  end
end


sam = Sam.new('William Samuel Jones, III')
son = Son.new('Billy Boy')

puts
puts "Count for me Doctor #{sam.name} ..."
puts sam.one    # from Sam
puts sam.two    # from Sam
puts sam.three  # from Sam
puts
puts "Count for me #{son.name} ..."
puts son.one    # from Son
puts son.two    # from Son and Sam
puts son.three  # from Sam
puts

__END__

$ ./son_of_sam.rb

Count for me Doctor William Samuel Jones, III ...
1
2
3

Count for me Billy Boy ...
11
22
33
