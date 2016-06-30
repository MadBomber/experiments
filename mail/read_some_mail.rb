#!/usr/bin/env ruby

require 'awesome_print'
require 'debug_me'
include DebugMe

require 'mail'

Mail.defaults do
  retriever_method :imap, :address    => "imap.gmail.com",
                          :port       => 993,
                          :user_name  => ENV['GMAIL_USER'],
                          :password   => ENV['GMAIL_PASS'],
                          :enable_ssl => true
end


emails = Mail.find(:what => :last, :count => 40, :order => :asc, :keys => 'ALL')


#ap emails.first.methods


emails.each do |mail|
  next unless mail.from.include? "newsletters@analystratings.net"

  print "\n\n"
  puts "Date: #{mail.date}"
  puts "HTML:"

  raw_source = mail.html_part.raw_source
  processed_source = raw_source.
                        gsub("=\r\n",     '').
                        gsub('=3D',       '=').
                        gsub('=E2=80=99', "'").
                        gsub('=E2=80=9C', '"').
                        gsub('=E2=80=9D', '"').
                        gsub('=E2=80=A6', '...')



  f= File.open('content.html','w')
  f.puts processed_source
  f.close

  raw_text        = `html2text content.html`
  processed_text  = raw_text.
                        gsub("\n(\n", " (").
                        gsub("\n)", ")").
                        gsub("Read More\n.  \nTweet This\n.", '')

  f= File.open('content.txt','w')
  f.puts processed_text
  f.close

  text_array = processed_text.split("\n")

  upgrades    = []
  downgrades  = []

  collect_up  = false
  collect_down= false

  text_array.each do |t|
    next if t.empty?
    next unless collect_up || t.downcase.start_with?("analysts' upgrades")
    unless collect_up
      collect_up = true
      next
    end
    if t.downcase.include?("analysts' upgrades")
      collect_up = false
      next
    end
    upgrades << t
  end

  text_array.each do |t|
    next if t.empty?
    next unless collect_down || t.downcase.start_with?("analysts' downgrades")
    unless collect_down
      collect_down = true
      next
    end
    if t.downcase.include?("analysts' downgrades")
      collect_down = false
      next
    end
    downgrades << t
  end


  # ap upgrades
  # ap downgrades

  re = Array.new

  # company_name
  # exchange
  # ticker_symbol
  # analyst
  # from_rating
  # to_rating
  # price_target
  # upside_percent
  # prev_close
  re << /^(?<company_name>.*) \((?<exchange>.*):(?<ticker_symbol>.*)\).*analysts at (?<analyst>.*) from a.* "(?<from_rating>.*)" rating .* "(?<to_rating>.*)".*\$(?<price_target>\d+.\d+) price target.* (?<upside_percent>.*)%.*\$(?<prev_close>\d+.\d+)/


  re << /^(?<company_name>.*) \((?<exchange>.*):(?<ticker_symbol>.*)\).*analysts at (?<analyst>.*) to a.* "(?<to_rating>.*)" rating\. .* \(\$(?<price_target>\d.\d+)\) price target/

  re << /^(?<company_name>.*) \((?<exchange>.*):(?<ticker_symbol>.*)\).*analysts at (?<analyst>.*) from a.* "(?<from_rating>.*)" rating .* "(?<to_rating>.*)".* closing price of \$(?<prev_close>\d+.\d+)/


  # BHP Billiton plc (LON:BLT)  was upgraded by analysts at Haitong Bank to a "buy" rating. They now have a GBX 1,002 ($13.22) price target on the stock, up previously from GBX 864 ($11.40).

  re << /^(?<company_name>.*) \((?<exchange>.*):(?<ticker_symbol>.*)\).*analysts at (?<analyst>.*) to a.*"(?<to_rating>.*)" rating\. .* now have a .*\$(?<price_target>\d+.\d+).* price target/

  # Crescent Point Energy Co. Ordinary Shares (Canada) (NYSE:CPG)  was upgraded by analysts at TD Securities to a "buy" rating. Previous closing price of $15.74.

  re << /^(?<company_name>.*) \((?<exchange>.*):(?<ticker_symbol>.*)\).*analysts at (?<analyst>.*) to a.*"(?<to_rating>.*)" rating\. .* closing price of \$(\d+.\d+)./


  # Ubm Plc (NASDAQ:UBMOF)  was upgraded by analysts at Bank of America from an "underperform" rating to a "neutral" rating.

  # Ubm Plc (NASDAQ:UBMOF)  was upgraded by analysts at Bank of America from an \"underperform\" rating to a \"neutral\" rating.

  re << /^(?<company_name>.*) \((?<exchange>.*):(?<ticker_symbol>.*)\).*analysts at (?<analyst>.*) from a.*"(?<from_rating>.*)" rating to a.*"(?<to_rating>.*)" rating\./

  # Priceline Group Inc (NASDAQ:PCLN)  was upgraded by analysts at Morgan Stanley from an \"equal weight\" rating to an \"overweight\" rating. They now have a $1,525.00 price target on the stock, up previously from $1,330.00. 23.0% upside from the previous close of $1,239.41.
  


  upgrades.each do |u|
    match_data = nil

    re.each do |r|
      match_data    = r.match u
      break unless match_data.nil?
    end

    if match_data.nil?
      puts
      puts "ERROR: Need new regexp for:"
      puts u
      puts
      next
    end

    company_name  = match_data.names.include?('company_name')   ? match_data[:company_name] : nil
    exchange      = match_data.names.include?('exchange')       ? match_data[:exchange] : nil
    ticker_symbol = match_data.names.include?('ticker_symbol')  ? match_data[:ticker_symbol] : nil
    analyst       = match_data.names.include?('analyst')        ? match_data[:analyst] : nil
    from_rating   = match_data.names.include?('from_rating')    ? match_data[:from_rating] : nil
    to_rating     = match_data.names.include?('to_rating')      ? match_data[:to_rating] : nil
    price_target  = match_data.names.include?('price_target')   ? match_data[:price_target] : nil
    upside_percent= match_data.names.include?('upside_percent') ? match_data[:upside_percent] : nil
    prev_close    = match_data.names.include?('prev_close')     ? match_data[:prev_close] : nil

    puts
    debug_me {[
        :u,
        :company_name,
        :exchange,
        :ticker_symbol,
        :analyst,
        :from_rating,
        :to_rating,
        :price_target,
        :upside_percent,
        :prev_close
      ]}

  end


=begin
Analysts' Upgrades
...
View today's most recent analysts' upgrades at MarketBeat.com

Analysts' Downgrades
...
View today's most recent analysts' downgrades at MarketBeat.com


=end


=begin
  debug_me{[ 
    #'mail.header_fields',
    #'mail.headers',
    #'mail.envelope_from',    #=> 'mikel@test.lindsaar.net'
    'mail.from',
    'mail.from_addrs',
    #'mail.from.addresses',   #=> ['mikel@test.lindsaar.net', 'ada@test.lindsaar.net']
    #'mail.sender.address',   #=> 'mikel@test.lindsaar.net'
    'mail.to',                #=> 'bob@test.lindsaar.net'
    'mail.cc',                #=> 'sam@test.lindsaar.net'
    'mail.subject',           #=> "This is the subject"
    'mail.date.to_s',         #=> '21 Nov 1997 09:55:06 -0600'
    'mail.message_id',        #=> '<4D6AA7EB.6490534@xxx.xxx>'
    #'mail.body.decoded',     #=> 'This is the body of the email...
    'mail.body',
    #'mail.html_part.methods',
    'mail.html_part.body',
    'mail.html_part.body.raw_source',
    #'mail.text_part.methods',
    #'mail.text_part.header',
    #'mail.text_part.body',
    'mail.text_part.body.raw_source'
  ]}
=end



end



__END__

mail.attachments.each do | attachment |
  # Attachments is an AttachmentsList object containing a
  # number of Part objects
  if (attachment.content_type.start_with?('image/'))
    # extracting images for example...
    filename = attachment.filename
    begin
      File.open(images_dir + filename, "w+b", 0644) {|f| f.write attachment.body.decoded}
    rescue => e
      puts "Unable to save data for #{filename} because #{e.message}"
    end
  end
end


