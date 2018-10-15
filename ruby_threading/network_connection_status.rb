#!/usr/bin/env ruby
# exoerunebts/ruby_threading/network_connection_status.rb

require 'active_support/all'  # A toolkit of support libraries and Ruby core extensions extracted from the Rails framework.
require 'awesome_print'       # Pretty print Ruby objects with proper indentation and colors
require 'debug_me'            # A tool to print the labeled value of variables.
include DebugMe
require 'faraday'        # HTTP/REST API client library.
require 'require_all'    # A wonderfully simple way to load your code

require 'thwait'         # STDLIB
require 'resolv'         # STDLIB

class NetworkConnectionStatus
  class << self
    # returns a hash keyed by external service name.
    # value is:
    #   true    connection is verified as good
    #   false   connection is verified as bad
    #   nil     connection can not be verified (most likely test not implemented)
    def test
      # Test the connection to all the external Services
      result = Hash.new
      test_threads  = Array.new

      subclasses.each do |klass|
        test_threads << Thread.new do
          Thread.current[:result] = klass.test
        end
      end

      ThreadsWait.all_waits(test_threads) do |test_thread|
        result.merge! test_thread.fetch(:result, {xyzzy: nil})
      end

      return result
    end # def test

    # test for network connection status return true/false/nil
    # api_url is the URL to check
    # timeout is interger seconds
    def web_service_active?(api_url, timeout: 20)
      return [nil, "No URL provided"] if api_url.nil?

      connection = Faraday.new do |faraday|
        faraday.adapter :typhoeus
        faraday.options.timeout = timeout
      end

      connection.options.timeout = timeout

      begin
        response        = connection.get(api_url)
        response_status = response.status
        details         = response.pretty_inspect
      rescue Exception => e
        response_status = 609
        details = e.to_s
      end

      if (200..299).include? response_status
        result = true
      elsif  (300..399).include? response_status
        result = false
      else
        result = nil
      end

      unless result
        details << "\n" + valid_ip?(api_url).last
      end

      return [result, details]
    end # def web_service_active?(api_url, timeout: 20, return_details: false)


    # determine if the domain name of the URL has a valid IP address
    def valid_ip?(url)
      # extract host name from a URL
      url_parsed = URI.parse(url)
      host = url_parsed.host

      if host.nil?
        result = [false, "Invalid URL: #{url}"]
        return result
      end

      host.downcase!

      # get IP address from a host name

      begin
        ip_address = Resolv.getaddress host
      rescue Resolv::ResolvError
        ip_address = nil
      end

      if ip_address.nil?
        result = [false, "unknown host: #{host}"]
      elsif '127.0.0.1' == ip_address
        result = [false, "unknown host: #{host} resolves to localhost; check /etc/hosts file"]
      else
        result = [true, "#{host} resolves to #{ip_address}"]
      end

      return result
    end # def valid_ip?(url)
  end # class << self
end # class NetworkConnectionStatus

require_all "./network_connection_status"

puts "\nTesting Web services in parallel-kinda ..."
status = NetworkConnectionStatus.test

max_key_size = status.keys.map{|k| k.size}.max + 3

s       = 'Web Service'
spaces  = " "*(max_key_size - s.size)
title   = "#{s} #{spaces} Status"

puts "\n#{title}"

status.each do |key, value|
  dots = "."*(max_key_size - key.size)
  puts "#{key} #{dots} #{value.first ? 'connected' : 'not connected'}"
end

puts
