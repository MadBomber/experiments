#!/usr/bin/env ruby
# encoding: utf-8
##########################################################
###
##  File: searcy_db.rb
##  Desc: Search a localhost rethinkdb for a keyword returns user_id
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'debug_me'
include DebugMe

require 'pathname'
require 'nenv'
require 'slop'

require 'rethinkdb'
include RethinkDB::Shortcuts

#require 'nobrainer'


# Example Custom Type for Slop
module Slop
  class PathOption < Option
    def call(value)
      Pathname.new(value)
    end
  end
  class PathsOption < ArrayOption
    def finish(opts)
      self.value = value.map { |f| Pathname.new(f) }
    end
  end
end # module Slop

me        = Pathname.new(__FILE__).realpath
my_dir    = me.parent
my_name   = me.basename.to_s
home_path = Pathname.new(Nenv.home)

$options = {
  version:        '0.0.1',# the version of this program
  arguments:      [],     # whats left after options and parameters are extracted
  verbose:        false,
  debug:          false,
  db_name:        'simplifi_development',
  table_name:     'transactions',
  user_name:      Nenv.user || Nenv.user_name || Nenv.logname || 'Dewayne VanHoozer'
}

def verbose?
  $options[:verbose]
end

def debug?
  $options[:debug]
end

HELP = <<EOHELP

Important:

  The search term must be presented via STDIN
  No stemming.
  No semantic search.
  The search is however case insensitive.

  Example:

    echo 'Toyota' | #{my_name}

EOHELP

opts = Slop.parse do |o|
  o.banner = "\nSearch for keywords in a localhost rethinkDB"
  o.separator "\nUsage: echo 'keyword' | #{my_name} [options]"
  o.separator "\nWhere:"
  o.separator "  options"

  o.on '-h', '--help', 'show this message' do
    puts o
    puts HELP if defined?(HELP)
    exit
  end

  o.bool '-v', '--verbose', 'enable verbose mode'
  o.bool '-d', '--debug',   'enable debug mode'

  o.separator "\n  parameters"

  o.string        '--db',    'database name',  default: $options[:db_name]
  o.string  '-t', '--table', 'table  in which data is stored',  default: $options[:table_name]


  o.on '--version', "print the version: #{$options[:version]}" do
    puts $options[:version]
    exit
  end
end

$options.merge!(opts.to_hash)
$options[:arguments] = opts.arguments

# Display the usage info
=begin
if  ARGV.empty?
  puts opts
  puts HELP if defined?(HELP)
  exit
end
=end

# Check command line for Problems with Parameters
$errors   = []
$warnings = []


# Display global warnings and errors arrays and exit if necessary
def abort_if_errors
  unless $warnings.empty?
    STDERR.puts
    STDERR.puts "The following warnings were generated:"
    STDERR.puts
    $warnings.each do |w|
      STDERR.puts "\tWarning: #{w}"
    end
    STDERR.print "\nAbort program? (y/N) "
    answer = (gets).chomp.strip.downcase
    $errors << "Aborted by user" if answer.size>0 && 'y' == answer[0]
    $warnings = []
  end
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




# NOTE: #r RethinkDB::Shortcuts
conn = r.connect(:host => 'localhost', :port => 28015).repl

db_exist = r.db_list.run.include?($options[:db_name])

unless db_exist
  $errors << "Database does not exist: #{$options[:db_name]}"
else
  conn.use($options[:db_name])
  table_list = r.table_list.run
  unless table_list.include?($options[:table_name])
    $errors << "The '#{$options[:table_name]}' table does not exist in database '#{$options[:db_name]}'"
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

pp $options  if verbose? || debug?




keyword = STDIN.gets().chomp

cursor  = r.table($options[:table_name]).
            filter{|trans| trans[:url].
              match("(?i)#{keyword}")}.
          run

puts <<EOS

The following user_id values should get an ad
placement based upon the search term: #{keyword}

EOS

cursor.each do |c|
  if verbose?
    puts
    puts "="*45
    pp c
  else
    puts c['user_id'] # FIXME: error in rethinkDB driver inconsistent use of symbol and string as keys
  end
end

puts

unless verbose?
  puts <<EOS
To see more detail regarding why these users were chosen,
rerun the search using the -v, --verbose option.

EOS
end

conn.close
