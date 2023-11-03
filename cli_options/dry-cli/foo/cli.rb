# Foo/cli.rb

require 'dry/cli'

module Dry::CLI::Banner
  class << self
    alias_method :original_call, :call

    def call(command, name)
    	global_header 	= Dry::CLI::Command.global_header
    	global_footer 	= Dry::CLI::Command.global_footer
      command_header 	= command.header
      command_footer 	= command.footer

      <<~EOS
      	#{global_header}
      	#{command_header}

      	#{original_call(command, name)}

      	#{command_footer}
      	#{global_footer}
      EOS
    end
  end
end


module Dry::CLI::Usage
  class << self
    alias_method :original_call, :call

    def call(result)
    	global_header 	= Dry::CLI::Command.global_header
    	global_footer 	= Dry::CLI::Command.global_footer

      <<~EOS
      	#{global_header}

      	#{original_call(result)}

      	#{global_footer}
      EOS
    end
  end
end


class Dry::CLI::Command
	def self.header(a_string=nil)
		if a_string.nil?
			@header_string
		else
			@header_string = a_string
		end
	end

	def self.footer(a_string=nil)
		if a_string.nil?
			@footer_string
		else
			@footer_string = a_string
		end
	end

	def self.global_header(a_string=nil)
		if a_string.nil?
			@@global_header_string
		else
			@@global_header_string = a_string
		end
	end

	def self.global_footer(a_string=nil)
		if a_string.nil?
			@@global_footer_string
		else
			@@global_footer_string = a_string
		end
	end
end


module Foo::CLI
end

# Load the Base and Version (aka PrintVersion) commands first
require_relative './cli/commands'


# execute the command line
Dry::CLI.new(Foo::CLI::Commands).call
