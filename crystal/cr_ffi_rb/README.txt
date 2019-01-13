# cr_ffi_rb/README.txt

I'm looking at how to make use of methods written in Crystal from Ruby.

Actually I'd kinda like to do something like this:

def my_method(*args)
  Inline::Crystal.new(
    # a metadata Hash that describes the arguments
    # and the class of the returned value
    source: # either a File object or a string
      <<~CRYSTAL
        body of a crystal method
      CRYSTAL
  )
end

The first time that the Inline::Crystal initialize method is called
for the enclosing method it will use the metadata and the source to
build an FFI access method.  The source will be wrapped with appropriate
crystal code to match the FFI that was build.  It will then be sent to
the crystal compiler to create the library.  The FFI code will then
be invoked against the library.

On subsequent accesses to my_method, the initializer method will
recognize that the FFI wrapper already exists and will call it directly.

The technique should work for any language.

# inline.rb

module Inline
  class Crystal
    def initialize(options)
      # TODO: get metadata from caller
      # TODO: combine with options
      # TODO: constructe the FFI wrapper if necessary
      # TODO: compile the source
      # TODO: execute the FFI wrapper
    end # def initialize(options)
  end # class Crystal
end # module Inline

Even though this may be a good idea, the crystal language does not support
dynamic shared libraries.  So that language will have to wait for a bit.  But
even so dpes this syntax have any benefit over a utility class that wraps
a full library of functions?  Don't think so.

It really kinda sucks after you spend some time with it.

The Go language on the other hand does support dynamic shared libraries.  But 
this inline concept still sucks.


