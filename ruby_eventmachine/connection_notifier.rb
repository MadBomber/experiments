#!/usr/bin/ruby
####################################################
## MacOS X : Uses Growl Notification to alert on
## a network connection.  Uses a diff technique
## against netstat output.
#
#  connection_notifier.rb
#  ConnectionNotifier
#
#  Copyright 2009 Paul Codding
#  All rights reserved.
#
#  Released under the BSD license.
require 'rubygems'
require File.dirname(__FILE__) + '/Growl'

class Connection
   include Comparable

attr_accessor
  :protocol, :local_ip, :remote_ip, :local_port, :remote_port, :id

   def initialize(connection_entry)
     pieces = connection_entry.split(" ")
     @protocol = pieces[0]
     @local_ip = pieces[3].split(".")[0..3].join(".")
     @remote_ip = pieces[4].split(".")[0..3].join(".")
     @local_port = pieces[3].split(".").last.to_i
     @remote_port = pieces[4].split(".").last.to_i
     @id = pieces[4].split(".").join()
   end

   def (other_connection)
     @id  other_connection.id
   end

   def to_s
     "#{@protocol} connection established from #{@remote_ip} to port #{@local_port}"
   end
end

class ConnectionNotifier
   GROWL_APP_NAME="Connection Notifier"

   def initialize
     @ports = Array.new(1024)
     @ports.fill { |port| port += 1}
     @connections = Array.new
     @growl = GrowlNotifier.new(GROWL_APP_NAME,['Ruby Connection Notifier'],nil,
                OSX::NSWorkspace.sharedWorkspace().iconForFileType_('rb'))
     @growl.register()

     # Pre-populate connections array so we're not automatically notified about
     # existing established connections
     check_for_new_connections(false)
     build_list_of_listening_ports()
   end

   # Poll for changes in netstat output
   def poll
     while true do
       sleep(2)
       check_for_new_connections(true)
     end
   end

   # Check for a new connection in the output of netstat
   def check_for_new_connections(notify)
     netstat_output = `netstat -na`
     for connection_entry in netstat_output do
       if connection_entry.include?("ESTABLISHED")
         connection = Connection.new(connection_entry)

         if connection.local_port != nil && @ports.include? (connection.local_port.to_i) \
           && !@connections.include?(connection)
           @connections << connection
           if (notify)
             @growl.notify('Ruby Connection Notifier', 'Connection Established',
               connection.to_s)
           end
         end
       end
     end
   end

   def build_list_of_listening_ports
     netstat_output = `netstat -na`
     for connection_entry in netstat_output do
       if connection_entry.include?("LISTEN")
         connection = Connection.new(connection_entry)
         if !@ports.include?(connection.local_port)
           @ports << connection.local_port
         end
       end
     end
   end
end

conn = ConnectionNotifier.new
conn.poll
