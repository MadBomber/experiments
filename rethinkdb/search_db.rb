#!/usr/bin/env ruby
# encoding: utf-8
##########################################################
###
##  File: searcy_db.rb
##  Desc: Search a localhost rethinkdb for a keyword returns user_id
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'cli_helper'
require 'rethinkdb_helper'

#require 'nobrainer'


HELP = <<EOHELP

Example:

    #{my_name} -i Toyota

EOHELP

thing = cli_helper("\nSearch for keywords in a localhost rethinkDB") do |o|

  o.string        '--db',    'database name',  default: 'simplifi_development'
  o.string  '-t', '--table', 'table  in which data is stored',  default: 'transactions'
  o.bool    '-i', '--insensitive', 'set case-insensitive', default: false

end

if $options[:arguments].empty?
  error 'No search terms were specified.  See --help'
else
  begin
    db = ReDBH.new($options)
  rescue Exception => e
    error e
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

ap $options  if verbose? || debug?

# TODO: handle more than one keyword
keyword = $options[:arguments].first

if insensitive?
  keyword = "(?i)#{keyword}"
end

cursor  = db.search( url: keyword )

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

db.close
