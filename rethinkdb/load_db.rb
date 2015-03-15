#!/usr/bin/env ruby
# encoding: utf-8
##########################################################
###
##  File: load_db.rb
##  Desc: Load the rethinkDB from a web search transaction file
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'debug_me'
include DebugMe

require 'pathname'
require 'nenv'
require 'slop'
require 'addressable/uri'
require "cgi"
require 'useragent'
require 'progress_bar'


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

data_dir  = my_dir + 'data'
trans_path= data_dir + 'parsed_data.txt'

$options = {
  version:        '0.0.1',# the version of this program
  arguments:      [],     # whats left after options and parameters are extracted
  verbose:        false,
  debug:          false,
  drop:           false,
  file:           trans_path,
  db_name:        'simplifi_development',
  table_name:     'transactions',
  user_name:      Nenv.user || Nenv.user_name || Nenv.logname || 'Dewayne VanHoozer',
  skip_cnt:       0
}

def verbose?
  $options[:verbose]
end

def debug?
  $options[:debug]
end

def drop?
  $options[:drop]
end


HELP = <<EOHELP

Important:

  No threads. 6 core 4.0Ghz workstation does about 40 t/s

EOHELP

opts = Slop.parse do |o|
  o.banner = "\nLoad a localhost rethinkDB from a transaction file"
  o.separator "\nUsage: #{my_name} [options] parameters"
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

  o.int           '--skip',  'skip some transactions',  default: $options[:skip_cnt]
  o.bool          '--drop',  'drop the database'
  o.string        '--db_name',    'database name',  default: $options[:db_name]
  o.string  '-t', '--table_name', 'table  in which data is stored',  default: $options[:table_name]
  o.path    '-f', '--file',  'transaction file', default: $options[:file]


  o.on '--version', "print the version: #{$options[:version]}" do
    puts $options[:version]
    exit
  end
end

$options.merge!(opts.to_hash)
$options[:arguments] = opts.arguments

# Display the usage info
if  ARGV.empty?
  puts opts
  puts HELP if defined?(HELP)
  exit
end


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
    pp $options
    exit(-1)
  end
end # def abort_if_errors



unless $options[:file].exist?
  $errors << "File does not exist: #{$options[:file]}"
end


abort_if_errors


######################################################
# Local methods

# SMELL: IPv6 ?
# SMELL: user_id funciton sucks
def process_transaction(a_hash)
  user_id = (a_hash[:ip] + a_hash[:user_agent]).hash
  a_hash[:user_id]      = user_id

  url_object   = Addressable::URI.parse(a_hash[:url])
  a_hash[:url_query]    = CGI::parse(url_object.query) unless url_object.query.nil?

  refer_object = Addressable::URI.parse(a_hash[:refer])
  a_hash[:refer_query]  = CGI::parse(refer_object.query) unless refer_object.query.nil?

# TODO: use UserAgent parser to tease out information from the UA parameter

  return a_hash
end # def process_transaction(a_hash)


######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

pp $options  if verbose? || debug?

# NOTE: #r RethinkDB::Shortcuts
# FIXME: mpve up the file, trap no db running
conn = r.connect(:host => 'localhost', :port => 28015).repl

db_exist = r.db_list.run.include?($options[:db_name])
r.db_drop($options[:db_name]) if db_exist && drop?
r.db_create($options[:db_name]).run unless db_exist
conn.use($options[:db_name])

table_exist = r.table_list.run.include?($options[:table_name])
r.table_create($options[:table_name]).run unless table_exist


total_lines = (`wc -l #{$options[:file]}`).split().first.to_i

line_cnt    = 0
trans_size  = 6
trans_cnt   = 0
trans_skip  = $options[:skip_cnt]


ip_cnt    = 0
u_cnt     = 0
r_cnt     = 0
ua_cnt    = 0
err_cnt   = 0


# SMELL: this program is full of bad-data holes;
#        there are many assumptions here that were
#        verified by an analysis of the data file.
#        A good programmer would put lots of bad-data
#        traps in to ensure that only good stuff
#        gets into the database.
bar = ProgressBar.new(total_lines / trans_size)


transaction = nil

start_time  = Time.now

$options[:file].readlines.each do |raw_line|
  # ISO-8859-1
  a_line = raw_line.chomp.strip.force_encoding("UTF-8") unless '*'==raw_line[0]
  trans_state = line_cnt % trans_size
  case trans_state
  when 0
    # TODO: start new transaction
    trans_cnt += 1
    transaction = Hash.new
  when 5
    # TODo: save transactiion
    trans_skip -= 1
    if trans_skip <= 0
      trans_hash = process_transaction(transaction)
      begin
        r.table($options[:table_name]).insert(
            trans_hash
          ).
          run
      rescue Exception => e
        err_cnt += 1
        $errors << "Trans No: #{trans_cnt} Error: #{e}"
        STDERR.puts $errors.last if verbose?
        # TODO: write the transaction to a bad-transaction file
      end
    end
    bar.increment!
  else
    case a_line[0,2]
    when 'IP'
      ip_cnt += 1
      ip = a_line[3,99999].strip
      ip = '0.0.0.0' if ip.empty?
      transaction[:ip] = ip

    when 'U:'
      u_cnt += 1
      url = a_line[2,99999].strip
      url = 'http' + url if url.start_with?('://')
      url = 'http://' + url if  !url.start_with?('http://') &&
                                url.size > 0                &&
                                !url.start_with?('file://')
      transaction[:url] = url
    when 'R:'
      r_cnt += 1
      transaction[:refer] = a_line[2,99999].strip
    when 'UA'
      ua_cnt += 1
      user_agent = a_line[3,99999].strip
      user_agent = 'unknown' if user_agent.empty?
      transaction[:user_agent] = user_agent
    else
      puts a_line
      err_cnt += 1
    end
  end
  line_cnt += 1
end # $options[:file].readlines.each do |raw_line|


end_time      = Time.now
elapsed_time  = end_time - start_time

conn.close

puts
debug_me{[
    :line_cnt,
    :trans_cnt,
    :ip_cnt,
    :u_cnt,
    :r_cnt,
    :ua_cnt,
    :err_cnt,
    :start_time,
    :end_time,
    :elapsed_time
  ]}

abort_if_errors
