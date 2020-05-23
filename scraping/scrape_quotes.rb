#!/usr/bin/env ruby
# .../experiments/scraping/scrape_quotes.rb
# Does not work on my old MacMini
# but does work on the linux fedora 31 machine
# something about websockets is causing the problem
# on the MacMini

require 'amazing_print'
require "json"
require "vessel"

class QuotesToScrapeCom < Vessel::Cargo
  domain "quotes.toscrape.com"
  start_urls "http://quotes.toscrape.com/tag/humor/"

  def parse
    css("div.quote").each do |quote|
      print '.'
      yield({
        author: quote.at_xpath("span/small").text,
        text: quote.at_css("span.text").text
      })
    end

    if next_page = at_xpath("//li[@class='next']/a[@href]")
      print '>'
      url = absolute_url(next_page.attribute(:href))
      yield request(url: url, method: :parse)
    end
  end
end

quotes = []
QuotesToScrapeCom.run { |q| quotes << q }
# puts JSON.generate(quotes)

puts; puts
ap quotes

