
start_time = Time.now

def my_random(upto)
  rand(upto)
end

100_000_000.times {|x| my_random(42)}

end_time = Time.now

puts end_time - start_time
