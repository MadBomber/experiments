#!/usr/bin/env ruby
##################################################
###
##  File: hoard_food.rb
##  Desc: Actually just get some recipe
##        No; really playing with mechanize
#

require 'exponential_backoff'
require 'mechanize'

module MechanizeBackoff

  def get(*args)

    begin
      ExponentialBackoff.try(2) { response = super }
    rescue => e
      e.errors # => [#<RuntimeError: Blah>, #<ConnectionError: Bleh>]
    end

  end
end

class Mechanize
  prepend MechanizeBackoff
end


mechanize = Mechanize.new

mechanize.user_agent_alias = 'Mac Safari'

chefs = CHEFS.read.split("\n")  #[]

chefs_url = 'http://www.bbc.co.uk/food/chefs'

chefs_page = mechanize.get(chefs_url)

chefs_page.links_with(href: /\/by\/letters\//).each do |link|
  atoz_page = mechanize.click(link)

  atoz_page.links_with(href: /\A\/food\/chefs\/\w+\z/).each do |link|
    chefs << link.href.split('/').last
  end
end


require 'fileutils'

search_url = 'http://www.bbc.co.uk/food/recipes/search?chefs[]='

chefs.each do |chef_id|

  results_pages = []

  begin
    results_pages << mechanize.get(search_url + chef_id)
  rescue Exception => e
    STDERR.puts "ERROR: chef id: #{chef_id}  msg: #{e}"
  end

  dirname = File.join('bbcfood', chef_id)

  FileUtils.mkdir_p(dirname)

  while results_page = results_pages.shift
    links = results_page.links_with(href: /\A\/food\/recipes\/\w+\z/)

    links.each do |link|
      path = File.join(dirname, File.basename(link.href) + '.html')

      next if File.exist?(path)

      STDERR.puts "+ #{path}"

      mechanize.download(link.href, path)
    end

    if next_link = results_page.links.detect { |link| link.rel?('next') }
      results_pages << mechanize.click(next_link)
    end
  end
end



