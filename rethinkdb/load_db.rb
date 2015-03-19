#!/usr/bin/env ruby
# encoding: utf-8
##########################################################
###
##  File: load_db.rb
##  Desc: Load the rethinkDB from a web search transaction file
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'cli_helper'
require 'rethinkdb_helper'

require 'addressable/uri'
require "cgi"
require 'useragent'
require 'progress_bar'


#require 'nobrainer'

HELP = <<EOHELP

Important:

  No threads. 6 core AMD 4.0Ghz workstation does about 40 t/s

EOHELP

cli_helper("\nLoad a localhost rethinkDB from a transaction file") do |o|

  o.int           '--skip',  'skip some transactions',  default: 0
  o.int     '-l', '--limit', 'Number of transactions to load', default: 100
  o.bool          '--drop',  'drop the database'
  o.string        '--db',    'database name',  default: 'simplifi_development'
  o.string  '-t', '--table', 'table  in which data is stored',  default: 'transactions'
  o.path    '-f', '--file',  'transaction file'

end


# Display the usage info
if  ARGV.empty?
  puts opts
  puts HELP if defined?(HELP)
  exit
end

unless $options[:file].exist?
  error "File does not exist: #{$options[:file]}"
end

begin
  db = ReDBH.new( $options.merge({create_if_missing: true}) )
rescue Exception => e
  error e
end

abort_if_errors


######################################################
# Local methods

# SMELL: IPv6 ?
# SMELL: user_id funciton sucks
def process_transaction(a_hash)
  user_id = (a_hash[:ip] + a_hash[:ua]).hash
  a_hash[:user_id]      = user_id

  url_object          = Addressable::URI.parse(a_hash[:url])
  a_hash[:url_query]  = CGI::parse(url_object.query) unless url_object.query.nil?

  refer_object          = Addressable::URI.parse(a_hash[:refer])
  a_hash[:refer_query]  = CGI::parse(refer_object.query) unless refer_object.query.nil?

  # FIXME: Waiting for UserAgent PR for #to_h method
  #ua_object           = UserAgent.parse(a_hash[:ua])
  #a_hash[:user_agent] = ua_object.to_h

  return a_hash
end # def process_transaction(a_hash)


######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

ap $options  if verbose? || debug?



total_lines = (`wc -l #{$options[:file]}`).split().first.to_i

line_cnt    = 0
trans_size  = 6
trans_cnt   = 0
trans_skip  = $options[:skip]


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
    trans_cnt += 1
    break if (0 != $options[:limit]) && (trans_cnt > $options[:limit])
    transaction = Hash.new
  when 5
    trans_skip -= 1
    if trans_skip <= 0
      trans_hash = process_transaction(transaction)
      begin
        db.insert(trans_hash)
      rescue Exception => e
        err_cnt += 1
        error "Trans No: #{trans_cnt} Error: #{e}"
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
      ua = a_line[3,99999].strip
      ua = 'unknown' if ua.empty?
      transaction[:ua] = ua
    else
      puts a_line
      err_cnt += 1
    end
  end
  line_cnt += 1
end # $options[:file].readlines.each do |raw_line|


end_time      = Time.now
elapsed_time  = end_time - start_time

db.close

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
