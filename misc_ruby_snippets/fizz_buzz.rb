# 100.times do |x|
#   print x       if 0 != x%3  and  0 != x%5
#   print 'Fizz'  if 0 == x%3
#   print 'Buzz'  if 0 == x%5
#   puts
# end


fizzbuzz = (0..99).to_a.map{|x| if 0 == x%15 then 'FizzBuzz' elsif 0 == x%5 then 'Buzz' elsif 0 == x%3 then 'Fizz' else x end} ; puts fizzbuzz
