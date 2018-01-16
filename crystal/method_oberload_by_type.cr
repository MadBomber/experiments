
# arguments are of undetermined type
def plus(a, b)
  a+b
end

puts "with int32 -=>  #{plus(1, 2)}"
puts %(with string -=>  #{plus("xy", "zzy")})


# arguments are of specific type with method overloading based upon argument types
def plus2(a, b)  # (a : Int32, b : Int32)
  a+b
end

def plus2(a : String, b : String)
  "Magic: "+a+b
end

puts "with int32 -=>  #{plus2(1, 2)}"
puts %(with string -=>  #{plus2("xy", "zzy")})
