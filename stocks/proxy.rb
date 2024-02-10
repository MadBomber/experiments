#!/usr/bin/env ruby
# experiments/stocks/proxy.rb
#
# an idea on how to parallelize access to a back-end
# server.  Run multiple instances of this program
# on ECS or EKS each with a different API key 
# and external IP address.
#
# The multiple instances will are behind an API
# gateway.  Client hits the gateway; gateway routes to
# a proxy; proxy hits the server and waits for the
# response; proxy gets response and returns it to
# the client.
#
# If the goal is to have different IP Addresses
# for each request, then maybe this is all you
# need according to the AI:
# With NordVPN's rotating residential proxies feature enabled, multiple requests can
# appear to come from different IP addresses.

SERVER_DOMAIN = ENV['SERVER_DOMAIN']
API_KEY       = ENV['API_KEY']

require("sinatra")
require("net/http")
require("uri")

set(:bind, "0.0.0.0")
set(:port, (ENV["PORT"] or 8080))

get("/*") { proxy_request("GET") }

post("/*") { proxy_request("POST") }


def proxy_request(req_type)
  upstream_uri  = URI.parse("https://#{SERVER_DOMAIN}#{request.fullpath}")
  http          = Net::HTTP.new(upstream_uri.host, upstream_uri.port)
  http.use_ssl  = true

  req   = if (req_type == "GET")
            Net::HTTP::Get.new(upstream_uri.request_uri)
          else
            Net::HTTP::Post.new(upstream_uri.request_uri)
          end

  req.body = request.body.read if (req_type == "POST")
  
  append_api_key_to_headers(req)

  response = http.request(req)

  status(response.code.to_i)

  response.header.each { |key, value| headers[key] = value }

  response.body

rescue StandardError => e
  status(500)
  e.message
end


def append_api_key_to_headers(req)
  req["x-api-key"] = API_KEY
  req
end
