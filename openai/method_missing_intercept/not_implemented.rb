# experiments/openai/method_missing_intercept/not_implemented.rb
#
# Desc: Create an exception-like class with class methods
#       that can at Runtime dynamically insert into a
#       Ruby source code file with code provided
#       as a response to an gen-AI prompt.
#
# SMELL:  This does not feel right.

require 'amazing_print'
require 'debug_me'
include DebugMe

require 'method_source'
require 'openai'


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
      file_path, file_line, temp  = caller[0].split(':')
      method_name                 = temp.split().last[1..-2].to_sym

      method_location = [file_path, file_line]
      klass, source   = find_method_source(method_name, method_location)


  		# TODO: craft a prompt
  		# TODO: send the prompt
  		# TODO: format the response
  		# TODO: insert the response
      # TODO: reload the updated file
      # TODO: retry the method
      # OR
      # TODO: raise and exception with the requirement_text
      # OR
      # TODO: STDERR.puts requirement_text and source file, line location
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
        #
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


    # What if the line which called me is a multi-line
    # executable like this:
    #   NotImplemented.needs_to <<~EOS
    #       do something
    #       more context
    #     EOS
    #
    # How do I get the extend of the lines that need to be
    # commented out?
    #
    # Could reduce memory by just pass the method source and
    # not the entire file.
    #
    def get_executable_line(
          file_path,              # Sring
          method_name,            # not needed?
          method_line_number,     # Integer line number in file for the "def"
          executable_line_number  # Integer line number in the file which starts NotImplemented ...
        )

      method_definition = File.readlines(file_path)[method_line_number - 1]
      method_definition_indentation = method_definition[/\A\s*/].size

      executable_lines  = []
      inside_method     = false
      num_indentation   = nil

      File.foreach(file_path).with_index do |line, line_number|
        if line_number == method_line_number - 1
          inside_method = true
          next
        end

        next unless inside_method

        line_indentation = line[/\A\s*/].size
        if num_indentation.nil? && line_indentation > method_definition_indentation
          num_indentation = line_indentation - method_definition_indentation
        end

        if line_indentation - method_definition_indentation >= num_indentation
          executable_lines << line.strip
        end

        if  line_number > method_line_number &&
            line.strip.empty?
          break
        end

        if line_number == executable_line_number - 1
          executable_line = executable_lines.join("\n")
          return executable_line
        end
      end
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



