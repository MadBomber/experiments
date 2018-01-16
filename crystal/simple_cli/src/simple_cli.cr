require "./simple_cli/*"

# TODO: Write documentation for `SimpleCli`
module SimpleCli
  # TODO: Put your code here
  puts "Elaboration time -- Nothing Done."

  def self.perform
    puts "Execution time -- nothing done etiher for version #{VERSION}."
  end


  def self.factorial_recursive( a : UInt64 )
    a <= 1 ? 1 : factorial_recursive(a * (a - 1))
  end


  def factorial_iterative( a : UInt64 )
    f = 1_u64
    (1..a).each do |i|
      f *= i
      puts i, f
    end
    f
  end

end # module SimpleCli

SimpleCli.perform

puts SimpleCli.factorial_iterative(50_u64)

puts SimpleCli.factorial_recursive(50_u64)


