# inline/go/initialize.rb

module Inline
  class Go
    def initialize(options)
      # TODO: get metadata from caller
      @metadata = caller
      @options  = options
      # TODO: constructe the FFI wrapper if necessary
      @ffi = ffi if @ffi.nil?
      # TODO: compile the source
      compile if true
      # TODO: execute the FFI wrapper
      execute
    end # def initialize(options)
  end # class Go
end # module Inline

