require 'amazing_print'
require 'debug_me'
include DebugMe

require 'method_source'

class NotImplemented
  class << self
    def needs_two(do_what="be written")
      file_path, file_line, temp  = caller[0].split(':')
      method_name                 = temp.split().last[1..-2].to_sym

      method_location = [file_path, file_line]

      debug_me{[
        :file_path,
        :file_line,
        :method_name,
        :method_location
      ]}

      klass, source = find_method_source(method_name, method_location)

      debug_me{[
        :klass,
        :source
      ]}


      # caller_method = caller_locations(1,1)[0].label
      # source = self.method(caller_method).source
      # puts source
    end

  	def needs_to(do_what="be written")
  		# TODO: get the source file and line which called
  		# TODO: klass.instance_method(:merge).source.display

  		source, line, temp 	= caller[0].split(':')
  		method_name 				= temp.split().last[1..-2]

  		debug_me{[
  			:do_what,
  			:source,
  			:line,
  			:method_name
  		]}


  		ap caller

  		raise RuntimeError

  		# TODO: craft a prompt
  		# TODO: send the promp
  		# TODO: format the response
  		# TODO: insert the response
  	end
  	alias_method :todo, 	:needs_to
  	alias_method :fixme, 	:needs_to

    #############################################
    ## Look for the method to get its source code

    # FIXME:  Need to match on method_name and method_location
    # method_name (Symbol) name of the caller
    # method_location (Array) [file_path, line_number]
    #
    def find_method_source(method_name, method_location)
      ObjectSpace.each_object(Class) do |klass|          # Iterate over all loaded classes
        # next unless "Calculator" == klass.name

        # if "Calculator" == klass.name
        #   puts "="*64
        #   debug_me{[
        #     :method_name,
        #     "method_name.class",
        #     "klass.method_defined?(method_name)"
        #   ]}
        #   puts "="*64
        # end


        next unless klass.method_defined?(method_name)   # Skip classes that don't have the method


        debug_me('==== here ===='){[
            :klass,
            :method_name,
            "method_name.class",
            "klass.method_defined?(method_name)"
        ]}


        # method_owner    = klass.instance_method(method_name).owner
        source_location = klass.instance_method(method_name).source_location

        next unless method_location.first == source_location&.first

        source          = klass.instance_method(method_name).source

        debug_me{[
          "klass.name",
          :source_location,
          :method_location,
          :source,
        ]}

        return [klass, source]
      end

      nil   # Return nil if method not found in any class
    end





  end
end


__END__


def find_method_owner(method_name)
  ObjectSpace.each_object(Class) do |klass|          # Iterate over all loaded classes
    next unless "Calculator" == klass.name

    if "Calculator" == klass.name
      puts "="*64
      debug_me{[
        :method_name,
        "method_name.class",
        "klass.method_defined?(method_name)"
      ]}
      puts "="*64
    end


    # next unless klass.method_defined?(method_name)   # Skip classes that don't have the method

    method_owner  = klass.instance_method(method_name).owner
    source_location = klass.instance_method(method_name).source_location
    source          = klass.instance_method(method_name).source
    source_display  = klass.instance_method(method_name).source.display

    debug_me{[
      :method_owner,
      :source_location,
      :source,
      :source_display
    ]}

    next unless method_owner.respond_to? :source_location

    return [klass, method_owner.source_location] if method_owner
  end

  nil   # Return nil if method not found in any class
end

# Usage example
method_name = :display
result = find_method_owner(method_name)

if result
  klass, (file_path, line_number) = result
  puts "Method #{method_name} found in class #{klass}, defined in file #{file_path} at line #{line_number}"
else
  puts "Method #{method_name} not found in any class"
end



