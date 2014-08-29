#!/usr/bin/env ruby -W0
##########################################################
###
##  File: notitional_dsl.rb
##  Desc: Just thinking out loud
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'debug_me'
require 'pathname'
require 'ostruct'

me        = Pathname.new(__FILE__).realpath
my_dir    = me.parent
my_name   = me.basename.to_s




def any_relationship(object1, object2)
  puts object1.class
  puts object2.class
  diatom = [object1, object2]
  if __callee__.to_s.end_with?('s')
    puts "#{__callee__} -=> #{object1}, #{object2}"
    object1.send("#{__callee__}=".to_sym, object2)
    object2.send("#{__callee__}=".to_sym, object1)
  else
    puts "#{object1} #{__callee__} #{object2}"
  end
  return diatom
end

alias :relationship                   :any_relationship
#alias :recipical_relationbships       :any_relationship
#alias :unidirectional_relationbships  :any_relationship
#alias :bidirectional_relationbships   :any_relationship

alias :parent_of                  :any_relationship
alias :child_of                   :any_relationship
#alias :friends                    :unidirectional_relationbships

#recipical_relationbships(  :parent_of, :child_of )

thing1        = OpenStruct.new(:name => 'thing1')
relationship  = OpenStruct.new
thing2        = OpenStruct.new(:name => 'thing2')
thing3        = OpenStruct.new(:name => 'thing3')

relationship(thing1, thing2)
parent_of(thing1, thing2)
child_of(thing2, thing1)

thing1.friends="none"
thing2.friends="none"
thing3.friends="none"

friends(thing2, thing3)

thing1.parent_of  = thing2
thing2.child_of   = thing1
thing2.friends    = thing3

pp thing1
pp thing2
pp thing3

puts thing1.respond_to? :parent_of
puts thing2.respond_to? :child_of
puts thing2.respond_to? :friends
puts thing3.respond_to? :friends






__END__

usage = <<EOS

__file_description__

Usage: #{my_name} [options] parameters

Where:

  options               Do This
    -h or --help        Display this message
    -v or --verbose     Display progress
    -o or --output      Specifies the path to the output
        out_filename      file.  The extname must be 'ics'
                          Defaults to STDOUT

  parameters            The parameters required by
                        the program

NOTE:

  Something_imporatant

EOS

# Check command line for Problems with Parameters
$errors = []


# Get the next ARGV parameter after param_index
def get_next_parameter(param_index)
  next_parameter = nil
  if param_index+1 >= ARGV.size
    $errors << "#{ARGV[param_index]} specified without parameter"
  else
    next_parameter = ARGV[param_index+1]
    ARGV[param_index+1] = nil
  end
  ARGV[param_index] = nil
  return next_parameter
end # def get_next_parameter(param_index)


# Get $options[:out_filename]
def get_out_filename(param_index)
  filename_str = get_next_parameter(param_index)
  $options[:out_filename] = Pathname.new( filename_str ) unless filename_str.nil?
end # def get_out_filename(param_index)


# Display global errors array and exit if necessary
def abort_if_errors
  unless $errors.empty?
    STDERR.puts
    STDERR.puts "Correct the following errors and try again:"
    STDERR.puts
    $errors.each do |e|
      STDERR.puts "\t#{e}"
    end
    STDERR.puts
    exit(-1)
  end
end # def abort_if_errors


# Display the usage info
if  ARGV.empty?               ||
    ARGV.include?('-h')       ||
    ARGV.include?('--help')
  puts usage
  exit
end

%w[ -v --verbose ].each do |param|
  if ARGV.include? param
    $options[:verbose]        = true
    ARGV[ ARGV.index(param) ] = nil
  end
end

%w[ -o --output ].each do |param|
  get_out_filename( ARGV.index(param) ) if ARGV.include?(param)
  unless $options[:out_filename].nil?
    unless $options[:out_filename].parent.exist?
      $errors << "Directory does not exist: #{$options[:out_filename].parent}"
    end
  end
end


ARGV.compact!

# ...


def abort_if_errors
  unless $errors.empty?
    STDERR.puts
    STDERR.puts "Correct the following errors and try again:"
    STDERR.puts
    $errors.each do |e|
      STDERR.puts "\t#{e}"
    end
    STDERR.puts
    exit(-1)
  end
end

abort_if_errors


######################################################
# Local methods


######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

pp $options

stub = <<EOS


   d888888o. 8888888 8888888888 8 8888      88 8 888888888o
 .`8888:' `88.     8 8888       8 8888      88 8 8888    `88.
 8.`8888.   Y8     8 8888       8 8888      88 8 8888     `88
 `8.`8888.         8 8888       8 8888      88 8 8888     ,88
  `8.`8888.        8 8888       8 8888      88 8 8888.   ,88'
   `8.`8888.       8 8888       8 8888      88 8 8888888888
    `8.`8888.      8 8888       8 8888      88 8 8888    `88.
8b   `8.`8888.     8 8888       ` 8888     ,8P 8 8888      88
`8b.  ;8.`8888     8 8888         8888   ,d8P  8 8888    ,88'
 `Y8888P ,88P'     8 8888          `Y88888P'   8 888888888P


EOS

puts stub









