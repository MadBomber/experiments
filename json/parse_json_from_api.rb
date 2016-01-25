#!/usr/bin/env ruby -wKU
###############################################
## Four ways to parse JSON from an API
## https://www.twilio.com/blog/2015/10/4-ways-to-parse-a-json-api-with-ruby.html
#

=begin
net/http

net/http is built into the Ruby standard library. There’s no gem to install and no dependencies to cause headaches down the road. If you value stability over speed of development, this is the right choice for you (for example, the twilio-ruby gem is built on net/http).

Unsurprisingly, using Net/http can require more work than using the gems built on top of it. For example, you have to create a URI object before making the HTTP request.
=end

require 'net/http'
require 'json'

url      = 'https://api.spotify.com/v1/search?type=artist&q=tycho'
uri      = URI(url)
response = Net::HTTP.get(uri)
a_hash   = JSON.parse(response)

=begin

HTTParty

net/http feels cumbersome and spartan at times. HTTParty was built on top of net/http in order to “Make HTTP fun again.” It adds a lot of convenience methods and can be used for all manners of HTTP requests. 

It also works quite nicely with RESTful APIs. Check out how calling parsed_response on a response parses the JSON without explicitly using the JSON library:

	gem install httparty

HTTParty also offers a command line interface — useful during development when trying to understand the structure of HTTP responses.
=end

require 'httparty'

url      = 'https://api.spotify.com/v1/search?type=artist&q=tycho'
response = HTTParty.get(url)
a_hash   = response.parsed_response

=begin

rest-client

rest-client is “a simple HTTP and REST client for Ruby, inspired by the Sinatra’s microframework style of specifying actions: get, put, post, delete.” Like HTTParty, it’s also built upon net/http. Unlike HTTParty, you’ll still need the JSON  library to parse the response.

	gem install rest-client

=end

require 'rest-client'
require 'json'

url      = 'https://api.spotify.com/v1/search?type=artist&q=tycho'
response = RestClient.get(url)
a_hash   = JSON.parse(response)

=begin

Faraday

Faraday is for developers who crave control. It has middleware to control all aspects of the request/response cycle. While rest-client and HTTParty lock you into net/http, Faraday lets you choose from seven HTTP Clients. For instance, you can use EventMachine for asynchronous request. (For the others, check out the github repo).

That customization means that our Faraday code snippet is more involved. Before we make our HTTP request and parse our results, we have to:

* Choose an HTTP adapter. The default is net/http.
* Identify the response type.
  - In this case we’ll use JSON, but you could also use XML or CSV.  

	gem install faraday
	gem install faraday_middleware

You’ll notice that we pass our query as optional parameters on the  get  method instead of concatanating them into the URL string. And because we’ve already told Faraday that the response is going to be JSON, we can call response.body and get back a parsed hash.

=end

require 'faraday'
require 'faraday_middleware'

url = 'https://api.spotify.com/v1'

conn = Faraday.new(url: url) do |faraday|
  faraday.adapter Faraday.default_adapter
  faraday.response :json
end

response = conn.get('search', type: 'artist', q: 'tycho')
a_hash   = response.body

