#!/usr/bin/env ruby
# nested.rb with optional commands desc in help block

require 'debug_me'
include DebugMe

require "tty-option"

module App
  class Command
    include TTY::Option

    header "** Useful?? **"
    footer "Another questionable experiment by the MadBomber"

    program "app"
    desc    "A Demonstration of Dynamic Nested Commands"

    flag :verbse do
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

    class << self
      @@subclasses          = []
      @@commands_available  = []

      def names
        '['+ @@commands_available.join('|')+']'
      end

      def inherited(subclass)
        super
        @@subclasses          << subclass
        @@commands_available  << subclass.command.join
      end

      def command_descriptions
        help_block = "Optional Command Available:"

        @@commands_available.size.times do |x|
          klass = @@subclasses[x]
          help_block << "\n  " + @@commands_available[x] + " - "
          help_block << klass.desc.join
        end

        help_block
      end
    end
  end


  class One < Command
    include TTY::Option

    desc "Do Number One"

    flag :one_flag_to_rule_them_all do
      long "--one"
      desc "Number One's Flag"
    end

    example "app one --one"
  end

  class Two < Command
    include TTY::Option

    desc "Do Number Two"

    flag :number_two do
      long '--two'
      desc "Flag Number Two"
    end

    example "app two --two"
  end
end


# First Load TTY-Option's command content with all available commands
# then these have access to the entire ObjectSpace ...
App::Command.command App::Command.names
App::Command.example App::Command.command_descriptions

# Demo the Help Content ...

cmds = App::Command.new
puts cmds.help

puts "="*42

one = App::One.new
puts one.help

puts "="*42

two = App::Two.new
puts two.help

