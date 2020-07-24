require "benchmark/ips"
require_relative "./method_overloading"

class Foo
  include MethodOverloading

  def call(number)
    "foo #{number}"
  end
end

class Bar
  def call(number)
    "bar #{number}"
  end
end

foo = Foo.new
bar = Bar.new

Benchmark.ips do |x|
  x.report("method overloading") { foo.call(23) }
  x.report("method") { bar.call(23) }
  x.compare!
end

__END__

Warming up --------------------------------------
  method overloading    24.146k i/100ms
              method   305.480k i/100ms
Calculating -------------------------------------
  method overloading    225.254k (±13.5%) i/s -      1.111M in   5.053180s
              method      3.274M (± 3.5%) i/s -     16.496M in   5.045562s

Comparison:
              method:  3273590.9 i/s
  method overloading:   225253.9 i/s - 14.53x  (± 0.00) slower
