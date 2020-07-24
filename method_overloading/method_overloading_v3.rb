require "benchmark/ips"

module MethodOverloading
  def self.included(klass)
    klass.class_eval do
      @_matches = Hash.new { |h, k| h[k] = {} }
      @_methods = {}
      @_recurse_catch = false

      def self.method_added(method_name)
        if @_recurse_catch
          @_recurse_catch = false
          return
        end

        original_method = instance_method(method_name)

        @_matches[method_name][original_method.arity] = original_method
        undef_method method_name

        # Prevent recursive calls to method_added if we're doing it
        # intentionally here.
        @_recurse_catch = true

        # Localize for closure
        method_matches = @_matches[method_name]

        if @_methods[method_name]
          define_method(method_name, @_methods[method_name])
        else
          define_method(method_name) do |*as|
            method_matches[as.size].bind(self).call(*as)
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
#   method overloading   126.264k i/100ms
#               method   255.798k i/100ms
# Calculating -------------------------------------
#   method overloading      1.711M (± 8.2%) i/s -      8.586M in   5.057014s
#               method      5.697M (± 3.3%) i/s -     28.649M in   5.035081s

# Comparison:
#               method:  5696723.0 i/s
#   method overloading:  1711428.7 i/s - 3.33x  slower
