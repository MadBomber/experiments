#!/usr/bin/env ruby
# nested.rb
# Using dynamic sub-commands that inherent from the
# main Command class.  This program demonstrates how
# the class methods in the main Command class are
# used to inform the help output.  It also demonstrates
# how to dispatch to the sub-commands for continued
# processing.

# This is used to keep the program from exiting while it
# is being demonstrated.
#
DO_NOT_EXIT = true


require "tty-option"

# Top-level Namespace for a CLI Application
module App

  # Top-level Command class from which all sub-commands inherent
  class Command
    include TTY::Option

    #########################################################
    # These Usage elements are for the top-level command only

    header "** Useful?? **"
    footer "Another questionable experiment by the MadBomber"

    program "app"
    desc    "A Demonstration of Dynamic Nested Commands"

    ########################################
    # Define common options for all commands

    flag :verbose do
      short "-v"
      long "--verbose"
      desc "Talk alot"
    end

    flag :debug do
      short "-d"
      long "--debug"
      desc "Use Native Intelligence (NI) to solve the problem"
    end

    flag :help do
      short "-h"
      long "--help"
      desc "Display help information"
    end

    # In this example the only config comes from
    # the command-line options processed by
    # TTY::Option.
    #
    # Config can be any class that holds an application-wide
    # configuration object such as TTY::Config or a Hashie::Dash
    # For this example, its a simple Hash.
    #
    # config is a Hash of the CLI options
    #
    attr_accessor :config


    # A common way to establish an instance of a command
    # and do something useful.
    def initialize(argv = ARGV)
      @config = parse_cli(argv).to_h
      # TODO: something useful
    end


    # Common parser interface that needs to
    # be tailored for each sub-commands unique
    # options.
    def parse_cli(argv)
      options = parse(argv).params

      if options.errors.any?
        puts
        puts options.errors.summary
        puts
        print parse.help
        exit(1) unless DO_NOT_EXIT

      elsif options[:help]
        puts
        print parse.help
        exit(0) unless DO_NOT_EXIT

      else
        # TODO: unique command handled by sub-commands
      end

      options
    end


    # Simple helper methods for all commands
    def debug?    = config[:debug]
    def verbose?  = config[:verbose]


    #################################################
    # Manage access to sub-commands with these
    # class methods:

    class << self
      @@subclasses          = [] # Array of Class.            Ex: App::One
      @@commands_available  = [] # Array of lowercase String. Ex: "one"

      # Accessed by the TTY::Option command method
      # outside of the class elaboration to insert
      # an optional sub-command list for use in the
      # help text.
      def names
        '['+ @@commands_available.join('|')+']'
      end


      # Keep track of all classes (aka sub-commands) that
      # inherent from this main Command class.
      def inherited(subclass)
        super
        @@subclasses          << subclass
        @@commands_available  << subclass.command.join
      end


      # Used to add a new section to the help/usage text
      # that lists all available sub-commands and their
      # descriptions.
      def command_descriptions
        help_block = "Optional Commands Available:"

        @@commands_available.size.times do |x|
          klass = @@subclasses[x]
          help_block << "\n  " + @@commands_available[x] + " - "
          help_block << klass.desc.join
        end

        help_block
      end


      ##################################################
      # Creates a new instance of a command or sub-command
      # What that instance does is up to what is coded in
      # its initialization method
      #
      def run(argv = ARGV)
        if argv.is_a? String
          argv = argv.split
        end

        # Tell the correct class/command to initialize
        dispatcher(argv)
      end


      # A sub-command must be the first thing
      # option on the CLI.  No sub-command should start
      # with a "-" character.
      def dispatcher(argv)
        if argv.first.start_with?('-')
          cmd = new(argv)
        else
          sub_cmd = argv.shift
          x       = @@commands_available.index sub_cmd
          if x.nil?
            puts
            puts "ERROR: There is no sub-command #{sub_cmd}"
            puts
            cmd = nil
            exit(1) unless DO_NOT_EXIT
          else
            cmd = @@subclasses[x].new(argv)
          end
        end

        cmd
      end
    end
  end


  #####################
  ## Sub-command ONE ##
  #####################

  class One < Command
    include TTY::Option

    # unique description and options for the sub-command

    desc "Do Number One"

    flag :one_flag_to_rule_them_all do
      long "--one"
      desc "Number One's Flag"
    end

    example "app one --one"

    # Use this pattern to actually do something
    # after instantiation.

    def initialize(argv)
      super
      puts "Doing the ONE thing"
    end


    # Augment the command method with unique CLI option
    # processing for this sub-command.

    def parse_cli(argv)
      options = super

      # Use the name of the flag not its
      # long value!
      if options[:one_flag_to_rule_them_all]
        puts "--one is TRUE"
      else
        puts "--one is FALSE"
      end

      options
    end
  end


  #####################
  ## Sub-command TWO ##
  #####################

  class Two < Command
    include TTY::Option

    # unique description and options for the sub-command

    desc "Do Number Two"

    flag :number_two do
      long '--two'
      desc "Flag Number Two"
    end

    example "app two --two"

    # Use this pattern to actually do something
    # after instantiation.

    def initialize(...)
      super
      puts "Doing the Texas TWO Step"
    end


    # Augment the command method with unique CLI option
    # processing for this sub-command.

    def parse_cli(argv)
      options = super

      # Use the name of the flag not its
      # long value!
      if options[:number_two]
        puts "--two is TRUE"
      else
        puts "--two is FALSE"
      end

      options
    end
  end
end

# require_relative 'sub_command_three'
# require_relative 'sub_command_four'
# require_relative 'sub_command_five'

####################################################################
## After all of the sub-commands have been loaded the ObjectSpace ##
## is now ready to be processed.  Do the following to customize   ##
## the HELP content of the common Command class.  Thise also      ##
## supports the dispatching to the specified sub-command.         ##
####################################################################

# First Load TTY-Option's command content with all available commands
# then these have access to the entire ObjectSpace ...
App::Command.command App::Command.names
App::Command.example App::Command.command_descriptions


##########################################
## Demo the dispatcher and Help Content ##
##########################################

puts "="*42
puts "Example: Calling without any sub-commands ...."
app = App::Command.run "--debug --verbose --help"

puts "="*42
puts "Example: Calling without any sub-commands AND bad options ...."
app = App::Command.run "--one --two --debug --verbose --help"

puts "="*42
puts "Example: Calling one sub-commands ...."

app = App::Command.run "one --one --debug --verbose --help"

puts "="*42
puts "Example: Calling two sub-commands ...."

app = App::Command.run "two --two --debug --verbose --help"

puts "="*42
puts "Example: Calling one directly ...."

app = App::One.run "--one --debug --verbose --help"

puts "="*42
puts "Example: Calling one directly with sub-command two...."

app = App::One.run "two --one --debug --verbose --help"

puts "="*42
puts "Example: Calling main command with invalid sub-command...."

app = App::Command.run "three --three --debug --verbose --help"
