# crystal ...
#   documentation:  https://crystal-lang.org/docs/
#   syntax is close to ruby but not the same in all cases.
#   a stongly typed language using LLVM
#   guesses at types when unspecified.
#   supports method overloading by type like Ada
#   requires the double quote for "string literals"

# execute this program like this:
#     crystal run hello_world.cr
# or
#     crystal hello_world.cr

# to compile this program into an executable:
#     crystal build hello_world.cr
# which produces the executable hello_world and a temp file hello_world.dwarf
#     crystal build hello_world.cr --release


puts "hello world"

words = [ "hello", "again", "world"]
puts words.join(" ")


