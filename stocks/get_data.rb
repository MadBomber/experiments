#!/usr/bin/env ruby
# experiments/stocks/get_data.rb

require 'amazing_print'
require 'debug_me'
include DebugMe

require 'faraday'
require 'nokogiri'

# Define the URL to Yahoo Finance and the ticker symbol:

base_url       = 'https://finance.yahoo.com'
ticker_symbol  = 'AAPL'

# Create a Faraday connection to the Yahoo Finance website:

connection = Faraday.new(url: base_url)

# Send a GET request to retrieve the webpage content:

response = connection.get("/quote/#{ticker_symbol}/history")

# debug_me{[
#    :response
# ]}


# Parse the response using Nokogiri to extract the historical price data:

doc   = Nokogiri::HTML(response.body)

# debug_me{[
#    :doc
# ]}

table = doc.css('table').first
rows  = table.css('tbody tr')

# Format the response as Markdown:

markdown = "| Date | Open | High | Low | Close | Adj Close | Volume |\n"
markdown += "|------|------|------|-----|-------|-----------|--------|\n"

rows.each do |row|
  cols = row.css('td')
  unless cols[1]&.text&.include?('Dividend')
     markdown += "| #{cols[0]&.text} | #{cols[1]&.text} | #{cols[2]&.text} | #{cols[3]&.text} | #{cols[4]&.text} | #{cols[5]&.text} | #{cols[6]&.text} |\n"
  end
end

# Output the formatted response:

puts markdown

