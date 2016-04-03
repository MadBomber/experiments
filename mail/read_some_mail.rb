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


emails = Mail.find(:what => :last, :count => 2, :order => :asc, :keys => 'ALL')


ap emails.first.methods


emails.each do |mail|

  print "\n\n"

  debug_me{[ 
    #'mail.header_fields',
    #'mail.headers',
    #'mail.envelope_from',   #=> 'mikel@test.lindsaar.net'
    'mail.from',
    'mail.from_addrs',
    #'mail.from.addresses',  #=> ['mikel@test.lindsaar.net', 'ada@test.lindsaar.net']
    #'mail.sender.address',  #=> 'mikel@test.lindsaar.net'
    'mail.to',              #=> 'bob@test.lindsaar.net'
    'mail.cc',              #=> 'sam@test.lindsaar.net'
    'mail.subject',         #=> "This is the subject"
    'mail.date.to_s',       #=> '21 Nov 1997 09:55:06 -0600'
    'mail.message_id',      #=> '<4D6AA7EB.6490534@xxx.xxx>'
    #'mail.body.decoded',    #=> 'This is the body of the email...
    'mail.body',
    'mail.html_part.methods',
    'mail.text_part.methods'
  ]}

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


