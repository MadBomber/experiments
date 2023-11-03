# foo/monkey_patch_dry_cli.rb

=begin
  This monkey patch Dry::CLI help capability with four new
  class methods added to the Command class:

    global_header .. Program/Glocal context custom header/footer
    global_footer ..
    header ......... Command context custom header / footer
    footer .........

  In addition to the new commands, tail-patched call methods in the
  Banner and Usage modules wrap the existing help text formatting
  with the appropriate global and command level header and footer
  text.

  Expected usage patter is to have the global customer
  header / footer help text defined in the Base command class
  for an application.  All other command inherent from this
  Base class.

  The header / footer class methods are used wrap the command
  help text.  When "--help" is used on a command, the customer
  global header and footer text are on the outside of the help text.
  The customized command header / footer are inside of the
  global context but still wrap the original help text

  Here is an example help output:

$ ./bin_cli.rb start --help
== Base Global Header ==
== Start Header ==
Command:
  bin_cli.rb start

Usage:
  bin_cli.rb start ROOT | bin_cli.rb start SUBCOMMAND

Description:
  Start Foo machinery

Subcommands:
  version                           # Print version

Arguments:
  ROOT                              # REQUIRED Root directory

Options:
  --[no-]debug, -d, --debug         # Print debug information, default: false
  --[no-]verbose, -v, --verbose     # Print verbose information, default: false
  --[no-]xyzzy, -x, --xyzzy         # Magic, default: false
  --help, -h                        # Print this help

Examples:
  bin_cli.rb start path/to/root # Start Foo at root directory
== Start Footer ==
== Base Global Footer ==


=end


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
