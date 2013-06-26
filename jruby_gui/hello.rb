#!/usr/bin/env ruby
###################################################
###
##  File: hello.rb
##  Desc: Simple example of a Java UI using Jruby
#

require 'java'

Sys         = java.lang.System
Runtime     = java.lang.Runtime

version     = Sys.getProperties["java.runtime.version"]
processors  = Runtime.getRuntime.availableProcessors

# With the 'require' above, we can now refer to things that are part of the
# standard Java platform via their full paths.
frame = javax.swing.JFrame.new("Window") # Creating a Java JFrame
label = javax.swing.JLabel.new("Hello from java.runtime.version #{version} with #{processors} processors")

# We can transparently call Java methods on Java objects, just as if they were defined in Ruby.
frame.add(label)  # Invoking the Java method 'add'.
frame.setDefaultCloseOperation(javax.swing.JFrame::EXIT_ON_CLOSE)
frame.pack
frame.setVisible(true)
