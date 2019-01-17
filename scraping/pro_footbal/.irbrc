require 'faraday'
require 'nokogiri'
require 'mechanize'
require 'loofah'

=begin
TH = Pathname.new('stats_table.html').read
        .gsub('</th>','|</th>')
        .gsub('</td>','|</td>')
        .gsub('<a','|<a')
T  = Loofah.fragment(TH)

puts T.text.gsub("\n\n", "\n").gsub('Team|','Team||City|')
=end

def get_stat(year, group)
  print "Year: #{year} Squad: #{group} ..."
  url = "https://www.footballdb.com/stats/teamstat.html?lg=NFL&yr=#{year}&type=reg&cat=T&group=#{group.upcase}&conf="
  out_file = File.open("#{year}_#{group}.html",'w')
  response = Faraday.get(url) # otta check for problems, but everything seems to work
  out_file.puts response.body
  out_file.close
  puts " done."
end

(1978..2018).each do |year|
  get_stat(year, 'O') # Offensive squad
  get_stat(year, 'D') # defensive squad
  sleep 5 # don't want the website to think I'm being greedy
end
