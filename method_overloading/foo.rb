require_relative "./method_overloading"

class Foo
  include MethodOverloading

  def call
    puts "foo"
  end

  def call(number)
    puts "foo #{number}"
  end
end

foo = Foo.new
foo.call # => "foo"
foo.call(23) # => "foo 23"
