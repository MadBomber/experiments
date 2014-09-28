#!/usr/bin/env ruby
##########################################################
###
##  File: edw_test.rb
##  Desc: Example of using the em-dir-watcher gem with the libnotify gem
#

require 'rubygems'
require 'em-dir-watcher'
require 'libnotify'

# Block syntax
n = Libnotify.new do |notify|
  notify.summary = "world"
  notify.body = "hello"
  notify.timeout = 4.5        # 1.5 (s), 1000 (ms), "2", nil, false
  notify.urgency = :critical  # :low, :normal, :critical
  notify.append = true        # default true - append onto existing notification
  notify.icon_path = "/usr/share/icons/gnome/scalable/emblems/emblem-default.svg"
end

=begin
n.show!

# Hash syntax
Libnotify.show(:body => "hello", :summary => "world", :timeout => 2.5)

# Mixed syntax
Libnotify.show(options) do |n|
  n.timeout = 1.5     # overrides :timeout in options
end
=end

puts "watching the current directory; make a change ..."
puts "Control-C to terminate."

EM.run {
    dw = EMDirWatcher.watch '.' do |paths|
        paths.each do |path|
            if File.exists? path
                puts "Modified: #{path}"
                n.summary = "File Modified"
                n.body    = "#{path}"
                n.show!
            else
                puts "Deleted: #{path}"
                n.summary = "File Deleted"
                n.body    = "#{path}"
                n.show!
            end
        end
    end
    puts "EventMachine running..."
}

