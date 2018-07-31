# inline/crystal/execute.rb

module Inline
  class Crystal
    def execute
      eval(@options[:source]) if @options.has_key? :source
    end # def execute
  end # class Crystal
end # module Inline
