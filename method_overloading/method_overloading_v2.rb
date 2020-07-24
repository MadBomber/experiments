require "benchmark/ips"

module MethodOverloading
  def self.included(klass)
    klass.class_eval do
      @_matches = {}
      @_methods = {}
      @_recurse_catch = false

      def self.method_added(method_name)
        if @_recurse_catch
          @_recurse_catch = false
          return
        end

        original_method = instance_method(method_name)

        @_matches[[method_name, original_method.arity]] = original_method
        undef_method method_name

        # Prevent recursive calls to method_added if we're doing it
        # intentionally here.
        @_recurse_catch = true

        # Localize for closure
        matches = @_matches

        if @_methods[method_name]
          define_method(method_name, @_methods[method_name])
        else
          define_method(method_name) do |*as, &fn|
            match = matches[[method_name, as.count]]
            match.bind(self).call(*as, &fn)
          end

          @_methods[method_name] = instance_method(method_name)
        end
      end
    end
  end
end

class Foo
  include MethodOverloading

  def call(number)
    "foo #{number}"
  end

  def call
    "foo 42"
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

# Warming up --------------------------------------
#   method overloading    57.941k i/100ms
#               method   252.803k i/100ms
# Calculating -------------------------------------
#   method overloading    641.658k (± 8.7%) i/s -      3.187M in   5.005621s
#               method      5.631M (± 3.4%) i/s -     28.314M in   5.034059s

# Comparison:
#               method:  5631177.7 i/s
#   method overloading:   641657.8 i/s - 8.78x  slower

