# Foo/cli.rb

require 'dry/cli'

#############################################################
## Monkey patch Dry::CLI objects until a PR is created/merged
#

module Dry::CLI::Banner
  class << self
    alias_method :original_call, :call

    # Overwrites the original 'call' method to accommodate a custom header and footer
    # for the help text.
    # @param command [Class] the the command class
    # @param name [String] command line without help option
    # @return [String] modified help text

    def call(command, name)
      help_text = original_call(command, name)

			my_header, my_footer = command_help_wrapper(command)

      help_text.prepend(my_header)
      help_text += my_footer

      help_text
    end


    # Provides the header and footer for the received command.
    # @param command [Class] the command class
    # @return [Array<String>] an array with the header at the 0 index and
    #                         the footer at the 1 index

    def command_help_wrapper(command)
    	global_header 	= Dry::CLI::Command.global_header
    	global_footer 	= Dry::CLI::Command.global_footer
      command_header 	= command.header
      command_footer 	= command.footer

      my_header = ""
      my_header += global_header + "\n"	unless (global_header.nil? || global_header.empty?)
      my_header += command_header+ "\n" unless (command_header.nil?|| command_header.empty?)

      my_footer = ""
      my_footer += "\n" + command_footer 	unless (command_footer.nil?|| command_footer.empty?)
      my_footer += "\n" + global_footer 	unless (global_footer.nil? || global_footer.empty?)

    	[my_header, my_footer]
    end
  end
end


module Dry::CLI::Usage
  class << self
    alias_method :original_call, :call

    # Overwrites the original 'call' method to allow a global header
    # and footer wrap for the help text.
    # @return [String] modified help text

    def call(result)
    	help_text = original_call(result)

    	global_header 	= Dry::CLI::Command.global_header
    	global_footer 	= Dry::CLI::Command.global_footer

    	help_text.prepend(global_header + "\n") unless (global_header.nil? || global_header.empty?)
    	help_text += "\n" + global_footer 			unless (global_footer.nil? || global_footer.empty?)

    	help_text
    end
  end
end


class Dry::CLI::Command
  # Provides a way to set a custom, command specific header.
  # @param a_string [String] optional, header text
  # @return [String] header text

  def self.header(a_string=nil)
		if a_string.nil?
			@header_string
		else
			@header_string = a_string
		end
	end


  # Provides a way to set a custom, command specific footer.
  # @param a_string [String] optional, footer text
  # @return [String] footer text

	def self.footer(a_string=nil)
		if a_string.nil?
			@footer_string
		else
			@footer_string = a_string
		end
	end


  # Provides a way to set a global custom header to overwrite the default one.
  # @param a_string [String] optional, global header text
  # @return [String] global header text

	def self.global_header(a_string=nil)
		if a_string.nil?
			@@global_header_string
		else
			@@global_header_string = a_string
		end
	end


  # Provides a way to set a global custom footer to overwrite the default one.
  # @param a_string [String] optional, global footer text
  # @return [String] global footer text

	def self.global_footer(a_string=nil)
		if a_string.nil?
			@@global_footer_string
		else
			@@global_footer_string = a_string
		end
	end
end

#
## End of Monkey patches
##############################################


module Foo::CLI
end

# Load the Base and Version (aka PrintVersion) commands first
# followed by all other commands and sub-commands
require_relative './cli/commands'


# #xecute the command line
Dry::CLI.new(Foo::CLI::Commands).call
