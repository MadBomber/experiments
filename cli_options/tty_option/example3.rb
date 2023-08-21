
require 'tty-option'

class CommonOptions
  include TTY::Option

  long "--verbose", "Enable verbose mode"
  long "--debug", "Enable debugging mode"

  def initialize(options)
    @options = options
  end

  def help
    puts "Usage: program.rb [options] command\n\n"
    puts "Common options:"
    print_option :verbose
    print_option :debug
    puts "\nAvailable commands: One, Two"
  end
end

class One
  include TTY::Option

  argument :arg1, required: true

  def initialize(options)
    @options = options
  end

  def help
    puts "Command One"
    puts "Usage: program.rb one [options]\n\n"
    puts "Options:"
    print_option :arg1
    puts "\nCommon options:"
    print_option :verbose
    print_option :debug
  end
end

class Two
  include TTY::Option

  def initialize(options)
    @options = options
  end

  def help
    puts "Command Two"
    puts "Usage: program.rb two [options]\n\n"
    puts "Common options:"
    print_option :verbose
    print_option :debug
  end
end

options = TTY::Option.parse(CommonOptions, ARGV)
command = ARGV.shift

case command
when 'one'
  TTY::Option.parse(One, ARGV)
when 'two'
  TTY::Option.parse(Two, ARGV)
else
  options.help
end
