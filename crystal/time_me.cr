# time_me.cr

# Ruby ...
# unless Time.respond_to? :measure
#   class Time
#     def self.measure
#       start_time = Time.now
#       yield
#       return Time.now - start_time
#     end
#   end
# end

def my_random(upto)
  rand(upto)
end

elapsed_time = Time.measure do
  100_000_000.times { |x| my_random(42) }
end

puts elapsed_time
