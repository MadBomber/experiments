#!/usr/bin/env ruby
############################################
###
##  File: rc_list.rb
##  Desc: Run all the status, report and list commands
##        using rabbitmqctl
#

require 'date'

puts "Bunny Stuff Report"
puts DateTime.now

the_commands = %w[
  status
  cluster_status
  environment
  list_bindings
  list_channels
  list_connections
  list_consumers
  list_exchanges
  list_parameters
  list_permissions
  list_policies
  list_queues
  list_users
  list_vhosts

]  # 'report' command gives all the same stuff in one report
   #   including 'list_user_permissions' for each user on each vhost

the_commands.each do |cmd|

  puts
  puts "#"*55
  puts "## #{cmd}"
  puts
  system("rabbitmqctl #{cmd}")

end


