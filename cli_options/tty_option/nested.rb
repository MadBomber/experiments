#!/usr/bin/env ruby
# nested.rb

require "tty-option"

module App
  class Command
    include TTY::Option

    header "** Useful?? **"
    footer "Another questionable experiment by the MadBomber"

    usage do
      program "app"
    end

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
      @@commands_available = []

      def names
        '['+ @@commands_available.join('|')+']'
      end

      def inherited(subclass)
        @@commands_available << subclass.to_s.downcase.split('::').last
      end
    end
  end


  class One < Command
    usage do
      program "app"
      desc "Do Number One"
    end

    flag :one_flag_to_rule_them_all do
      long "--one"
      desc "Number One's Flag"
    end
  end

  class Two < Command
    usage do
      program "app"
      desc "Do Number Two"
    end

    flag :number_two do
      long '--two'
      desc "Flag Number Two"
    end
  end
end


# Load TTY-Option's command content with available commands
App::Command.command App::Command.names

cmds = App::Command.new
puts cmds.help

puts "="*42

one = App::One.new
puts one.help

puts "="*42

two = App::Two.new
puts two.help

