#!/bin/env ruby
require 'rubygems'
require 'dnsruby'
require 'pp'

res = Dnsruby::Resolver.new
Dnsruby::Resolver.use_eventmachine
Dnsruby::Resolver.start_eventmachine_loop(true) # default
q = Queue.new
id = res.send_async(Dnsruby::Message.new("example.com"),q)
id, response, error = q.pop

pp response

