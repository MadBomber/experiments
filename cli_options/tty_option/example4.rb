#!/usr/bin/env ruby

require 'tty-option'

module CommonOptions
  def self.included(base)
    base.option :verbose, long: "--verbose", desc: "Enable verbose mode"
    base.option :debug, long: "--debug", desc: "Enable debugging mode"
  end

  def print_common_options
    puts "\nCommon options:"
    print_option :verbose
    print_option :debug
  end
end

class Common
  include TTY::Option
  include CommonOptions

  def initialize(options)
    @options = options
  end

  def help
    puts "Usage: program.rb [options] command\n\n"
    print_common_options
    puts "\nAvailable commands: One, Two"
  end
end

class One
  include TTY::Option
  include CommonOptions

  argument :arg1, required: true

  def initialize(options)
    @options = options
  end

  def help
    puts "Command One"
    puts "Usage: program.rb one [options]\n\n"
    puts "Options:"
    print_option :arg1
    print_common_options
  end
end

class Two
  include TTY::Option
  include CommonOptions

  def initialize(options)
    @options = options
  end

  def help
    puts "Command Two"
    puts "Usage: program.rb two [options]\n\n"
    print_common_options
  end
end

options = TTY::Option.parse(Common, ARGV)
command = ARGV.shift

case command
when 'one'
  TTY::Option.parse(One, ARGV)
when 'two'
  TTY::Option.parse(Two, ARGV)
else
  options.help
end
