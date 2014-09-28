#!/usr/bin/env ruby

require 'eventmachine'

EM.run do
 df = EM::Protocols::HttpClient.request(:host => '127.0.0.1',
                                        :request => '/')

 df.callback do |response|
   puts "Succeeded: #{response[:status]}"
   EM.stop
 end

 df.errback do |response|
   puts "ERROR: #{response[:status]}"
   EM.stop
 end

end

