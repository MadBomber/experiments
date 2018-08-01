# inline/go/execute.rb

module Inline
  class Go
    def execute
      eval(@options[:source]) if @options.has_key? :source
    end # def execute
  end # class Go
end # module Inline
