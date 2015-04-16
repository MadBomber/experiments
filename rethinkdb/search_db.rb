#!/usr/bin/env ruby
# encoding: utf-8
##########################################################
###
##  File: searcy_db.rb
##  Desc: Search a localhost rethinkdb for a keyword returns user_id
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'awesome_print'

require 'cli_helper'
include CliHelper

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
  o.string  '-u', '--user',  'ignore the keywords and tell me about the user'

end

if configatron.arguments.empty?  &&  configatron.user.nil?
  error 'No search terms were specified.  See --help'
else
  begin
    $db = RDB.new(configatron.to_h)
  rescue Exception => e
    error e
  end
end

abort_if_errors


unless $db.index_list.include?('user_id')
  print 'Creating user_id index ... '
  $db.create_simple_index('user_id')
  print 'waiting ... '
  $db.wait_on_index('user_id')
  puts 'done'
end


######################################################
# Local methods

def search_for_keywords
  total_found = 0
  # TODO: handle more than one keyword
  keyword = configatron.arguments.first

  if insensitive?
    keyword = "(?i)#{keyword}"
  end

  cursor  = $db.search( url: keyword )

  puts
  puts "The following user_id values should get an ad"
  puts "placement based upon the search term: #{keyword}"
  puts

  users = []

  cursor.each do |c|
    total_found += 1
    if verbose?
      puts
      puts "="*45
      pp c
    end
    users << c['user_id']
  end

  result = $db.get_all($db.r.args(users), index: 'user_id').group(:user_id).count.run

  puts "\nRecap of user_id and their total transactions on file:"
  ap result

  puts

  if verbose?
    puts "\n\nTotal found: #{total_found}"
    puts "To see more detail regarding why these users were chosen,"
    puts "rerun the search using the -v, --verbose option."
  end
end # def search_for_keywords


def search_for_user(user_id)
  total_found = 0

  cursor  = $db.search( user_id: user_id )

  puts
  puts "The following transactions were made by user ID #{configatron.user}"
  puts

  cursor.each do |c|
    total_found += 1
    puts
    puts "="*45
    ap c
  end

  if verbose?
    puts "\n\nTotal found: #{total_found}"
  end

end # def search_for_user

######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

ap configatron.to_h  if verbose? || debug?


if configatron.user.nil?
  search_for_keywords
else
  search_for_user configatron.user
end

puts "Users with more than 3 transactions:"
users = $db.table.group(:user_id).count.gt(3).run

users.each_pair do |k,v|
  print "#{k}, " if v
end

$db.close
