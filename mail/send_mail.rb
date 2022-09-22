#!/usr/bin/env ruby
#########################################################
###
##  File: send_mail.rb
##  Desc: send an eMail
##
#

require 'date'          # STDLIB
require 'load_gems'     # from my lib/ruby directory

load_gems %w[ amazing_print cli_helper debug_me loofah 
              mail net-smtp net-imap ]

include DebugMe
include CliHelper

configatron.version = '0.0.1'

HELP = <<EOHELP
Important:

  ... stuff goes here

EOHELP

cli_helper("__file_description__") do |o|
  o.string  '-u', '--user',     "user's email account",     default: ENV['GMAIL_USER']
  o.string  '-p', '--password', "user's email password",    default: ENV['GMAIL_PASS']
end

if configatron.user.nil?  || configatron.user.empty?
  print "gMail Username: "
  configatron.user = STDIN.gets.chomp
end

if configatron.password.nil?  || configatron.password.empty?
  print "gMail Password: "
  configatron.password = STDIN.noecho(&:gets).chomp
  puts
end

######################################################
# Local methods

def config_email_server
  Mail.defaults do
    delivery_method(  :smtp, 
                      address:    "smtp.gmail.com",
                      port:       465,
                      enable_ssl: true,
                      name:       'Dewayne VanHoozer',
                      user_name:  configatron.user,
                      password:   configatron.password,
                   )

    # retriever_method( :imap, 
    #                   address:    "imap.gmail.com",
    #                   port:       993,
    #                   enable_ssl: true,
    #                   name:       'Dewayne VanHoozer',
    #                   user_name:  configatron.user,
    #                   password:   configatron.password,
    #                   enable_ssl: true,
    #                 )
  end
end


######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

ap configatron.to_h  if verbose? || debug?

# puts "Retrieving eMails ..."
# emails = Array(
#             Mail.find( what:   :last,
#                     count:  configatron.days,      # how many days back from today
#                     order:  :asc,
#                     keys:   'FROM newsletters@analystratings.net')
#           )

=begin

config_email_server

mail = Mail.new do
  from     'dewayne@vanhoozer.me'
  to       'dvanhoozer@gmail.com'
  subject  'send_mail.rb test 5'
  body     "Hello eMail World\nHow are you?\n" 
  # File.read('body.txt')
  # add_file :filename => 'somefile.png', :content => File.read('/somefile.png')
end

puts "="*35
puts mail.to_s
puts "="*35

mail.deliver
=end


Mail.defaults do
  delivery_method :smtp, {
    address:    "smtp.gmail.com",
    port:       587,
    user_name:  ENV['GMAIL_USER'],
    password:   ENV['GMAIL_PASS'],
    authentication: :plain,
    enable_starttls_auto: true
  }
end

Mail.deliver do
  to      "dewayne@vanhoozer.me"
  from    "dvanhoozer@gmail.com"
  subject 'This is a test email 7'
  body    'hello body'
end






__END__


Making an email

mail = Mail.new do
  from    'mikel@test.lindsaar.net'
  to      'you@test.lindsaar.net'
  subject 'This is a test email'
  body    File.read('body.txt')
end

mail.to_s #=> "From: mikel@test.lindsaar.net\r\nTo: you@...

Making an email, have it your way:

mail = Mail.new do
  body File.read('body.txt')
end

mail['from'] = 'mikel@test.lindsaar.net'
mail[:to]    = 'you@test.lindsaar.net'
mail.subject = 'This is a test email'

mail.header['X-Custom-Header'] = 'custom value'

mail.to_s #=> "From: mikel@test.lindsaar.net\r\nTo: you@...

Don't Worry About Message IDs:

mail = Mail.new do
  to   'you@test.lindsaar.net'
  body 'Some simple body'
end

mail.to_s =~ /Message\-ID: <[\d\w_]+@.+.mail/ #=> 27

Mail will automatically add a Message-ID field if it is 
missing and give it a unique, random Message-ID along 
the lines of:

<4a7ff76d7016_13a81ab802e1@local.host.mail>

Or do worry about Message-IDs:

mail = Mail.new do
  to         'you@test.lindsaar.net'
  message_id '<ThisIsMyMessageId@some.domain.com>'
  body       'Some simple body'
end

mail.to_s =~ /Message\-ID: <ThisIsMyMessageId@some.domain.com>/ #=> 27

Mail will take the message_id you assign to it trusting that you know what you are doing.
Sending an email:

Mail defaults to sending via SMTP to local host port 25. 
If you have a sendmail or postfix daemon running on this port, 
sending email is as easy as:

Mail.deliver do
  from     'me@test.lindsaar.net'
  to       'you@test.lindsaar.net'
  subject  'Here is the image you wanted'
  body     File.read('body.txt')
  add_file '/full/path/to/somefile.png'
end

or

mail = Mail.new do
  from     'me@test.lindsaar.net'
  to       'you@test.lindsaar.net'
  subject  'Here is the image you wanted'
  body     File.read('body.txt')
  add_file :filename => 'somefile.png', :content => File.read('/somefile.png')
end

mail.deliver!

Sending via sendmail can be done like so:

mail = Mail.new do
  from     'me@test.lindsaar.net'
  to       'you@test.lindsaar.net'
  subject  'Here is the image you wanted'
  body     File.read('body.txt')
  add_file :filename => 'somefile.png', :content => File.read('/somefile.png')
end

mail.delivery_method :sendmail

mail.deliver

Sending via smtp (for example to mailcatcher)

Mail.defaults do
  delivery_method :smtp, address: "localhost", port: 1025
end

Exim requires its own delivery manager, and can be used like so:

mail.delivery_method :exim, :location => "/usr/bin/exim"

mail.deliver

Mail may be "delivered" to a logfile, too, for development and testing:

# Delivers by logging the encoded message to $stdout
mail.delivery_method :logger

# Delivers to an existing logger at :debug severity
mail.delivery_method :logger, logger: other_logger, severity: :debug

Getting Emails from a POP or IMAP Server:

You can configure Mail to receive email using retriever_method within Mail.defaults:

# e.g. POP3
Mail.defaults do
  retriever_method :pop3, :address    => "pop.gmail.com",
                          :port       => 995,
                          :user_name  => '<username>',
                          :password   => '<password>',
                          :enable_ssl => true
end

# IMAP
Mail.defaults do
  retriever_method :imap, :address    => "imap.mailbox.org",
                          :port       => 993,
                          :user_name  => '<username>',
                          :password   => '<password>',
                          :enable_ssl => true
end

You can access incoming email in a number of ways.

The most recent email:

Mail.all    #=> Returns an array of all emails
Mail.first  #=> Returns the first unread email
Mail.last   #=> Returns the last unread email

The first 10 emails sorted by date in ascending order:

emails = Mail.find(:what => :first, :count => 10, :order => :asc)
emails.length #=> 10

Or even all emails:

emails = Mail.all
emails.length #=> LOTS!

Reading an Email

mail = Mail.read('/path/to/message.eml')

mail.envelope_from   #=> 'mikel@test.lindsaar.net'
mail.from.addresses  #=> ['mikel@test.lindsaar.net', 'ada@test.lindsaar.net']
mail.sender.address  #=> 'mikel@test.lindsaar.net'
mail.to              #=> 'bob@test.lindsaar.net'
mail.cc              #=> 'sam@test.lindsaar.net'
mail.subject         #=> "This is the subject"
mail.date.to_s       #=> '21 Nov 1997 09:55:06 -0600'
mail.message_id      #=> '<4D6AA7EB.6490534@xxx.xxx>'
mail.decoded         #=> 'This is the body of the email...

Many more methods available.
Reading a Multipart Email

mail = Mail.read('multipart_email')

mail.multipart?          #=> true
mail.parts.length        #=> 2
mail.body.preamble       #=> "Text before the first part"
mail.body.epilogue       #=> "Text after the last part"
mail.parts.map { |p| p.content_type }  #=> ['text/plain', 'application/pdf']
mail.parts.map { |p| p.class }         #=> [Mail::Message, Mail::Message]
mail.parts[0].content_type_parameters  #=> {'charset' => 'ISO-8859-1'}
mail.parts[1].content_type_parameters  #=> {'name' => 'my.pdf'}

Mail generates a tree of parts. Each message has many or no parts. Each part is another message which can have many or no parts.

A message will only have parts if it is a multipart/mixed or multipart/related content type and has a boundary defined.
Testing and Extracting Attachments

mail.attachments.each do | attachment |
  # Attachments is an AttachmentsList object containing a
  # number of Part objects
  if (attachment.content_type.start_with?('image/'))
    # extracting images for example...
    filename = attachment.filename
    begin
      File.open(images_dir + filename, "w+b", 0644) {|f| f.write attachment.decoded}
    rescue => e
      puts "Unable to save data for #{filename} because #{e.message}"
    end
  end
end

Writing and Sending a Multipart/Alternative (HTML and Text) Email

Mail makes some basic assumptions and makes doing the common thing as simple as possible.... (asking a lot from a mail library)

mail = Mail.deliver do
  to      'nicolas@test.lindsaar.net.au'
  from    'Mikel Lindsaar <mikel@test.lindsaar.net.au>'
  subject 'First multipart email sent with Mail'

  text_part do
    body 'This is plain text'
  end

  html_part do
    content_type 'text/html; charset=UTF-8'
    body '<h1>This is HTML</h1>'
  end
end

Mail then delivers the email at the end of the block and returns the resulting Mail::Message object, which you can then inspect if you so desire...

puts mail.to_s #=>

To: nicolas@test.lindsaar.net.au
From: Mikel Lindsaar <mikel@test.lindsaar.net.au>
Subject: First multipart email sent with Mail
Content-Type: multipart/alternative;
  boundary=--==_mimepart_4a914f0c911be_6f0f1ab8026659
Message-ID: <4a914f12ac7e_6f0f1ab80267d1@baci.local.mail>
Date: Mon, 24 Aug 2009 00:15:46 +1000
Mime-Version: 1.0
Content-Transfer-Encoding: 7bit


----==_mimepart_4a914f0c911be_6f0f1ab8026659
Content-ID: <4a914f12c8c4_6f0f1ab80268d6@baci.local.mail>
Date: Mon, 24 Aug 2009 00:15:46 +1000
Mime-Version: 1.0
Content-Type: text/plain
Content-Transfer-Encoding: 7bit

This is plain text
----==_mimepart_4a914f0c911be_6f0f1ab8026659
Content-Type: text/html; charset=UTF-8
Content-ID: <4a914f12cf86_6f0f1ab802692c@baci.local.mail>
Date: Mon, 24 Aug 2009 00:15:46 +1000
Mime-Version: 1.0
Content-Transfer-Encoding: 7bit

<h1>This is HTML</h1>
----==_mimepart_4a914f0c911be_6f0f1ab8026659--

Mail inserts the content transfer encoding, the mime version, the content-IDs and handles the content-type and boundary.

Mail assumes that if your text in the body is only us-ascii, that your transfer encoding is 7bit and it is text/plain. You can override this by explicitly declaring it.
Making Multipart/Alternate, Without a Block

You don't have to use a block with the text and html part included, you can just do it declaratively. However, you need to add Mail::Parts to an email, not Mail::Messages.

mail = Mail.new do
  to      'nicolas@test.lindsaar.net.au'
  from    'Mikel Lindsaar <mikel@test.lindsaar.net.au>'
  subject 'First multipart email sent with Mail'
end

text_part = Mail::Part.new do
  body 'This is plain text'
end

html_part = Mail::Part.new do
  content_type 'text/html; charset=UTF-8'
  body '<h1>This is HTML</h1>'
end

mail.text_part = text_part
mail.html_part = html_part

Results in the same email as done using the block form
Getting Error Reports from an Email:

@mail = Mail.read('/path/to/bounce_message.eml')

@mail.bounced?         #=> true
@mail.final_recipient  #=> rfc822;mikel@dont.exist.com
@mail.action           #=> failed
@mail.error_status     #=> 5.5.0
@mail.diagnostic_code  #=> smtp;550 Requested action not taken: mailbox unavailable
@mail.retryable?       #=> false

Attaching and Detaching Files

You can just read the file off an absolute path, Mail will try to guess the mime_type and will encode the file in Base64 for you.

@mail = Mail.new
@mail.add_file("/path/to/file.jpg")
@mail.parts.first.attachment? #=> true
@mail.parts.first.content_transfer_encoding.to_s #=> 'base64'
@mail.attachments.first.mime_type #=> 'image/jpg'
@mail.attachments.first.filename #=> 'file.jpg'
@mail.attachments.first.decoded == File.read('/path/to/file.jpg') #=> true

Or You can pass in file_data and give it a filename, again, mail will try and guess the mime_type for you.

@mail = Mail.new
@mail.attachments['myfile.pdf'] = File.read('path/to/myfile.pdf')
@mail.parts.first.attachment? #=> true
@mail.attachments.first.mime_type #=> 'application/pdf'
@mail.attachments.first.decoded == File.read('path/to/myfile.pdf') #=> true

You can also override the guessed MIME media type if you really know better than mail (this should be rarely needed)

@mail = Mail.new
@mail.attachments['myfile.pdf'] = { :mime_type => 'application/x-pdf',
                                    :content => File.read('path/to/myfile.pdf') }
@mail.parts.first.mime_type #=> 'application/x-pdf'

Of course... Mail will round trip an attachment as well

@mail = Mail.new do
  to      'nicolas@test.lindsaar.net.au'
  from    'Mikel Lindsaar <mikel@test.lindsaar.net.au>'
  subject 'First multipart email sent with Mail'

  text_part do
    body 'Here is the attachment you wanted'
  end

  html_part do
    content_type 'text/html; charset=UTF-8'
    body '<h1>Funky Title</h1><p>Here is the attachment you wanted</p>'
  end

  add_file '/path/to/myfile.pdf'
end

@round_tripped_mail = Mail.new(@mail.encoded)

@round_tripped_mail.attachments.length #=> 1
@round_tripped_mail.attachments.first.filename #=> 'myfile.pdf'

See "Testing and extracting attachments" above for more details.
Using Mail with Testing or Spec'ing Libraries

If mail is part of your system, you'll need a way to test it without actually sending emails, the TestMailer can do this for you.

require 'mail'
=> true
Mail.defaults do
  delivery_method :test
end
=> #<Mail::Configuration:0x19345a8 @delivery_method=Mail::TestMailer>
Mail::TestMailer.deliveries
=> []
Mail.deliver do
  to 'mikel@me.com'
  from 'you@you.com'
  subject 'testing'
  body 'hello'
end
=> #<Mail::Message:0x19284ec ...
Mail::TestMailer.deliveries.length
=> 1
Mail::TestMailer.deliveries.first
=> #<Mail::Message:0x19284ec ...
Mail::TestMailer.deliveries.clear
=> []

There is also a set of RSpec matchers stolen/inspired by Shoulda's ActionMailer matchers (you'll want to set delivery_method as above too):

Mail.defaults do
  delivery_method :test # in practice you'd do this in spec_helper.rb
end

describe "sending an email" do
  include Mail::Matchers

  before(:each) do
    Mail::TestMailer.deliveries.clear

    Mail.deliver do
      to ['mikel@me.com', 'mike2@me.com']
      from 'you@you.com'
      subject 'testing'
      body 'hello'
    end
  end

  it { is_expected.to have_sent_email } # passes if any email at all was sent

  it { is_expected.to have_sent_email.from('you@you.com') }
  it { is_expected.to have_sent_email.to('mike1@me.com') }

  # can specify a list of recipients...
  it { is_expected.to have_sent_email.to(['mike1@me.com', 'mike2@me.com']) }

  # ...or chain recipients together
  it { is_expected.to have_sent_email.to('mike1@me.com').to('mike2@me.com') }

  it { is_expected.to have_sent_email.with_subject('testing') }

  it { is_expected.to have_sent_email.with_body('hello') }

  # Can match subject or body with a regex
  # (or anything that responds_to? :match)

  it { is_expected.to have_sent_email.matching_subject(/test(ing)?/) }
  it { is_expected.to have_sent_email.matching_body(/h(a|e)llo/) }

  # Can chain together modifiers
  # Note that apart from recipients, repeating a modifier overwrites old value.

  it { is_expected.to have_sent_email.from('you@you.com').to('mike1@me.com').matching_body(/hell/)

  # test for attachments

  # ... by specific attachment
  it { is_expected.to have_sent_email.with_attachments(my_attachment) }

  # ... or any attachment
  it { is_expected.to have_sent_email.with_attachments(any_attachment) }

  # ... or attachment with filename
  it { is_expected.to have_sent_email.with_attachments(an_attachment_with_filename('file.txt')) }

  # ... or attachment with mime_type
  it { is_expected.to have_sent_email.with_attachments(an_attachment_with_mime_type('application/pdf')) }

  # ... by array of attachments
  it { is_expected.to have_sent_email.with_attachments([my_attachment1, my_attachment2]) } #note that order is important

  #... by presence
  it { is_expected.to have_sent_email.with_any_attachments }

  #... or by absence
  it { is_expected.to have_sent_email.with_no_attachments }

end


#########################################
# IMAPv4 RFC 3501 March 2003
# Section 6.4.4 the SEARCH command
# value for 'keys:' can take on these values


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


