#!/usr/bin/env ruby

require 'awesome_print'
require 'debug_me'
include DebugMe

require 'mail'

Mail.defaults do
  retriever_method :imap, :address    => "108.177.8.109",  # "imap.gmail.com",
                          :port       => 993,
                          :user_name  => ENV['GMAIL_USER'],
                          :password   => ENV['GMAIL_PASS'],
                          :enable_ssl => true
end


emails = Mail.find(:what => :first, :count => 1, :order => :asc, :keys => 'ALL')


debug_me{[ :emails ]}