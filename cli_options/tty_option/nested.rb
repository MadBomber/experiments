#!/usr/bin/env ruby
# nested.rb

require 'debug_me'
include DebugMe



require "tty-option"

module App
  class Command
    include TTY::Option

    class_eval File.open(__dir__ + '/common_options.txt').read

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
    include TTY::Option

    usage do
      desc "Do Number One"
    end

    flag :one_flag_to_rule_them_all do
      long "--one"
      desc "Number One's Flag"
    end

    example "app one --one"

    class_eval File.open(__dir__ + '/common_options.txt').read


  end

  class Two < Command
    include TTY::Option

    usage do
      desc "Do Number Two"
    end

    flag :number_two do
      long '--two'
      desc "Flag Number Two"
    end

    example "app two --two"

    class_eval File.open(__dir__ + '/common_options.txt').read

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



