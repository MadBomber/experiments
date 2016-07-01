#!/usr/bin/env ruby

require 'awesome_print'
require 'debug_me'
include DebugMe

require 'progress_bar'
require 'rethinkdb_helper'
require 'date'

require 'mail'



###################################################################
## Regular Expressions to extract data from upgrades and downgrades

re = Array.new

# The first regular expression should get everything.
# company_name
# exchange
# ticker_symbol
# analyst
# from_rating
# to_rating
# price_target
# percent_change
# prev_close
re << /^(?<company_name>.*) \((?<exchange>.*):(?<ticker_symbol>.*)\).*analysts at (?<analyst>.*) from a.* "(?<from_rating>.*)" rating .* "(?<to_rating>.*)".*\$(?<price_target>[1-9]\d?(?:,\d{3})*(?:\.\d{2})?) price target.* (?<percent_change>.*)%.*\$(?<prev_close>[1-9]\d?(?:,\d{3})*(?:\.\d{2})?)/


# company_name, exchange, ticker_symbol, analyst, to_rating, price_target
re << /^(?<company_name>.*) \((?<exchange>.*):(?<ticker_symbol>.*)\).*analysts at (?<analyst>.*) to a.*"(?<to_rating>.*)" rating\. .* \(\$(?<price_target>\d+.\d+)\) price target/


# company_name, exchange, ticker_symbol, analyst, to_rating, prev_close
re << /^(?<company_name>.*) \((?<exchange>.*):(?<ticker_symbol>.*)\).*analysts at (?<analyst>.*) from a.*"(?<from_rating>.*)" rating to a.*"(?<to_rating>.*)" rating\. .*closing price of \$(?<prev_close>\d+.\d+)\./


# company_name, exchange, ticker_symbol, analyst, to_rating, prev_close
re << /^(?<company_name>.*) \((?<exchange>.*):(?<ticker_symbol>.*)\).*analysts at (?<analyst>.*) .*to a.*"(?<to_rating>.*)" rating\. .*closing price of \$(?<prev_close>\d+.\d+)\./


# The last regular expression should get only the most common.
# company_name, exchange, ticker_symbol, analyst, to_rating
re << /^(?<company_name>.*) \((?<exchange>.*):(?<ticker_symbol>.*)\).*analysts at (?<analyst>.*) from a.*"(?<from_rating>.*)".*to a.*"(?<to_rating>.*)" rating\./


# Shawbrook Group PLC (LON:SHAW)  was downgraded by analysts at Barclays to an "equal weight" rating. 

# company_name, exchange, ticker_symbol, analyst, to_rating
re << /^(?<company_name>.*) \((?<exchange>.*):(?<ticker_symbol>.*)\).*analysts at (?<analyst>.*) .*to a.*"(?<to_rating>.*)" rating\./

########################################################


Mail.defaults do
  retriever_method :imap, address:    "imap.gmail.com",
                          port:       993,
                          user_name:  ENV['GMAIL_USER'],
                          password:   ENV['GMAIL_PASS'],
                          enable_ssl: true
end


emails = Mail.find( what:   :last, 
                    count:  10000,      # how many days back from today
                    order:  :asc, 
                    keys:   'FROM newsletters@analystratings.net')

bar = ProgressBar.new(emails.size)


# IMAPv4 RFC 3501 March 2003
# Section 6.4.4 the SEARCH command
# value for 'keys:' can take on these values

=begin

      ALL
         All messages in the mailbox; the default initial key for
         ANDing.

      ANSWERED
         Messages with the \Answered flag set.

      BCC <string>
         Messages that contain the specified string in the envelope
         structure's BCC field.

      BEFORE <date>
         Messages whose internal date (disregarding time and timezone)
         is earlier than the specified date.

      BODY <string>
         Messages that contain the specified string in the body of the
         message.

      CC <string>
         Messages that contain the specified string in the envelope
         structure's CC field.

      DELETED
         Messages with the \Deleted flag set.

      DRAFT
         Messages with the \Draft flag set.

      FLAGGED
         Messages with the \Flagged flag set.

      FROM <string>
         Messages that contain the specified string in the envelope
         structure's FROM field.

      HEADER <field-name> <string>
         Messages that have a header with the specified field-name (as
         defined in [RFC-2822]) and that contains the specified string
         in the text of the header (what comes after the colon).  If the
         string to search is zero-length, this matches all messages that
         have a header line with the specified field-name regardless of
         the contents.

      KEYWORD <flag>
         Messages with the specified keyword flag set.

      LARGER <n>
         Messages with an [RFC-2822] size larger than the specified
         number of octets.

      NEW
         Messages that have the \Recent flag set but not the \Seen flag.
         This is functionally equivalent to "(RECENT UNSEEN)".

      NOT <search-key>
         Messages that do not match the specified search key.

      OLD
         Messages that do not have the \Recent flag set.  This is
         functionally equivalent to "NOT RECENT" (as opposed to "NOT
         NEW").

      ON <date>
         Messages whose internal date (disregarding time and timezone)
         is within the specified date.

      OR <search-key1> <search-key2>
         Messages that match either search key.

      RECENT
         Messages that have the \Recent flag set.

      SEEN
         Messages that have the \Seen flag set.

      SENTBEFORE <date>
         Messages whose [RFC-2822] Date: header (disregarding time and
         timezone) is earlier than the specified date.

      SENTON <date>
         Messages whose [RFC-2822] Date: header (disregarding time and
         timezone) is within the specified date.

      SENTSINCE <date>
         Messages whose [RFC-2822] Date: header (disregarding time and
         timezone) is within or later than the specified date.

      SINCE <date>
         Messages whose internal date (disregarding time and timezone)
         is within or later than the specified date.

      SMALLER <n>
         Messages with an [RFC-2822] size smaller than the specified
         number of octets.

      SUBJECT <string>
         Messages that contain the specified string in the envelope
         structure's SUBJECT field.

      TEXT <string>
         Messages that contain the specified string in the header or
         body of the message.

      TO <string>
         Messages that contain the specified string in the envelope
         structure's TO field.

      UID <sequence set>
         Messages with unique identifiers corresponding to the specified
         unique identifier set.  Sequence set ranges are permitted.

      UNANSWERED
         Messages that do not have the \Answered flag set.

      UNDELETED
         Messages that do not have the \Deleted flag set.

      UNDRAFT
         Messages that do not have the \Draft flag set.

      UNFLAGGED
         Messages that do not have the \Flagged flag set.

      UNKEYWORD <flag>
         Messages that do not have the specified keyword flag set.

      UNSEEN
         Messages that do not have the \Seen flag set.

=end

#ap emails.first.methods


db = RDB.new( db: 'analyst_ratings', table: 'upsndowns', drop: true, create_if_missing: true )


emails.each do |mail|
  bar.increment!
  next unless mail.from.include? "newsletters@analystratings.net"

  # puts "Date: #{mail.date}"

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

  analysts_pronouncements = upgrades + downgrades
 
  analysts_pronouncements.each do |ac|
    record = Hash.new
    record[:date] = mail.date.to_time

    match_data = nil

    re.each do |r|
      match_data    = r.match ac
      break unless match_data.nil?
    end

    if match_data.nil?
      puts
      puts "ERROR: Need new regexp for:"
      puts ac
      puts
      next
    end

    %w[ company_name  exchange      ticker_symbol   analyst  from_rating
        to_rating     price_target  percent_change  prev_close
        ].each do |field|
      symbol = field.to_sym
      record[ symbol ] = match_data.names.include?(field)   ? match_data[symbol] : nil
    end

    # print "\n\n"
    # debug_me {[
    #     :u,
    #     :record
    #   ]}

    db.insert(record)

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


