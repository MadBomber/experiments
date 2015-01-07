#!/usr/bin/env ruby
# encoding: utf-8
##########################################################
###
##  File: send_to.rb
##  Desc: Send either a voice message or an SMS to a phone number
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

class Time
  def before?(a_time)
    (self <=> a_time) < 0
  end
  def after?(a_time)
    (self <=> a_time) > 0
  end
  # a_string is expected to be in the form of hours[:minutes[:seconds]]
  # where hours is 0..23 minutes is 0..59 seconds is 0..59
  def self.parse(a_string, tn=Time.now)
    hms = a_string.scan(/\d+/).map(&:to_i)
    new(tn.year, tn.month, tn.day,
      hms[0], (hms.size>1 ? hms[1] : 0), (hms.size>2 ? hms[2] : 0))
  end
end # class Time

require 'debug_me'
include DebugMe

require 'nenv'

$twilio = Nenv :twilio

tftd = "Thought for the Day:"
Nenv.tftd = "#{tftd} Spending time with God daily makes a good spiritual diet."

Nenv.voice_url = "https://s3.amazonaws.com/voice.devotional.upperroom.org/en/20140401_en.mp3"
Nenv.voice_xml_url = "https://s3.amazonaws.com/voice.devotional.upperroom.org/en/20140401_en.xml"

Nenv.sales_ad = "Your contributions to The Upper Room help make this resource available.  Thank you for your support."

Nenv.simple_message_url = "http://twimlets.com/message?Message%5B0%5D=https%3A%2F%2Fs3.amazonaws.com%2Fvoice.devotional.upperroom.org%2Fen%2F20150107_en.mp3&Message%5B1%5D=Your%20contributions%20to%20The%20Upper%20Room%20help%20make%20this%20resource%20available.%20%20Thank%20you%20for%20your%20support.&"

Nenv.echo_url = "http://twimlets.com/echo?Twiml=%3CResponse%3E%0A%20%20%3CPlay%3Ehttps%3A%2F%2Fs3.amazonaws.com%2Fvoice.devotional.upperroom.org%2Fen%2F20140401_en.mp3%3C%2FPlay%3E%0A%20%20%3CSay%3EPlease%20consider%20a%20donation%20or%20a%20subscription%20to%20The%20Upper%20Room%20so%20that%20we%20may%20continue%20to%20provide%20resources%20to%20support%20your%20spiritual%20growth.%20%20Thank%20you%20and%20may%20God%20bless%20your%20day.%3C%2FSay%3E%0A%3C%2FResponse%3E&"


Nenv.voice_url = "http://twimlets.com/echo?Twiml=%3CResponse%3E%3CSay%3EHow+well+do+I+imitate+God+in+word+and+deed%3F%3C%2FSay%3E%3C%2FResponse%3E"
Nenv.sms_url = "http://twimlets.com/echo?Twiml=%3CResponse%3E%3CSms%3EHow+well+do+I+imitate+God+in+word+and+deed%3F%3C%2FSms%3E%3C%2FResponse%3E"


require 'pathname'

me        = Pathname.new(__FILE__).realpath
my_dir    = me.parent
my_name   = me.basename.to_s

$options = {
  verbose:        false,
  voice:          false,
  sms:            false,
  mms:            false,
  auto_validate:  false,
  disable:        false,
  list:           false,
  new_app:        false,
  update_app:     false,
  send_at:        Time.now,   # --at 'year/month/day hh:mm:ss'
  phone_numbers:  []
}

def verbose?
  $options[:verbose]
end

def voice?
  $options[:voice]
end

def sms?
  $options[:sms]
end

def mms?
  $options[:mms]
end

def auto_validate?
  $options[:auto_validate]
end

def disable?
  $options[:disable]
end

def list?
  $options[:list]
end

def new_app?
  $options[:new_app]
end

def update_app?
  $options[:update_app]
end


def valid_phone_number?(phone_number)
  /^\d{10}$/ === phone_number
end

usage = <<EOS

Send either a voice and/or an SMS message to a phone number

Usage: #{my_name} [options] phone_number

Where:

  options               Do This
    -h or --help        Display this message
    -v or --verbose     Display progress
          --all         Turns on voice, sms and mms
          --voice       Send voice message
          --sms         Send SMS message
          --mms         Send MMS message using
                          TUR cover graphic
          --validate    Auto-validate outgoing phone numbers
          --disable     Disable outgoing phone numbers
          --at          Delay action until specific date/time
            send_at       '[year/month/day] hh:mm:ss'
                          the date component is optional defaults to today

  phone_number+         The mobil phone number destination(s)

NOTE:

  For the trial account only verified phone numbers can be reached.

  Verified Numbers are:
    Dewayne:  817-905-1687
    Jorge:    615-828-5975
    Gary:     615-268-8522
    Doug:     615-557-3824


EOS

# Check command line for Problems with Parameters
$errors   = []
$warnings = []


# Get the next ARGV parameter after param_index
def get_next_parameter(param_index)
  unless Fixnum == param_index.class
    param_index = ARGV.find_index(param_index)
  end
  next_parameter = nil
  if param_index+1 >= ARGV.size
    $errors << "#{ARGV[param_index]} specified without parameter"
  else
    next_parameter = ARGV[param_index+1]
    ARGV[param_index+1] = nil
  end
  ARGV[param_index] = nil
  return next_parameter
end # def get_next_parameter(param_index)


# Get $options[:out_filename]
def get_out_filename(param_index)
  filename_str = get_next_parameter(param_index)
  $options[:out_filename] = Pathname.new( filename_str ) unless filename_str.nil?
end # def get_out_filename(param_index)


# Display global warnings and errors arrays and exit if necessary
def abort_if_errors
  unless $warnings.empty?
    STDERR.puts
    STDERR.puts "The following warnings were generated:"
    STDERR.puts
    $warnings.each do |w|
      STDERR.puts "\tWarning: #{w}"
    end
    STDERR.print "\nAbort program? (y/N) "
    answer = (gets).chomp.strip.downcase
    $errors << "Aborted by user" if answer.size>0 && 'y' == answer[0]
  end
  unless $errors.empty?
    STDERR.puts
    STDERR.puts "Correct the following errors and try again:"
    STDERR.puts
    $errors.each do |e|
      STDERR.puts "\t#{e}"
    end
    STDERR.puts
    exit(-1)
  end
end # def abort_if_errors


# Display the usage info
if  ARGV.empty?               ||
    ARGV.include?('-h')       ||
    ARGV.include?('--help')
  puts usage
  exit
end

%w[ -v --verbose ].each do |param|
  if ARGV.include? param
    $options[:verbose]        = true
    ARGV[ ARGV.index(param) ] = nil
  end
end

%w[ --all ].each do |param|
  if ARGV.include? param
    $options[:voice]        = true
    $options[:sms]          = true
    $options[:mms]          = true
    ARGV[ ARGV.index(param) ] = nil
  end
end

%w[ --voice ].each do |param|
  if ARGV.include? param
    $options[:voice]        = true
    ARGV[ ARGV.index(param) ] = nil
  end
end

%w[ --sms ].each do |param|
  if ARGV.include? param
    $options[:sms]            = true
    ARGV[ ARGV.index(param) ] = nil
  end
end

%w[ --mms ].each do |param|
  if ARGV.include? param
    $options[:mms]            = true
    ARGV[ ARGV.index(param) ] = nil
  end
end

%w[ --list ].each do |param|
  if ARGV.include? param
    $options[:list]            = true
    ARGV[ ARGV.index(param) ] = nil
  end
end

%w[ --new ].each do |param|
  if ARGV.include? param
    $options[:new_app]            = true
    ARGV[ ARGV.index(param) ] = nil
  end
end

%w[ --update ].each do |param|
  if ARGV.include? param
    $options[:update_app]            = true
    ARGV[ ARGV.index(param) ] = nil
  end
end

%w[ --delete ].each do |param|
  if ARGV.include? param
    $options[:delete_app]            = true
    ARGV[ ARGV.index(param) ] = nil
  end
end

%w[ --validate ].each do |param|
  if ARGV.include? param
    $options[:auto_validate]  = true
    ARGV[ ARGV.index(param) ] = nil
  end
end

# SMELL: This has no protection from bad parameter
%w[ --at ].each do |param|
  if ARGV.include? param
    tn = Time.now
    values = get_next_parameter(ARGV.index(param)).split(' ')
    if values.size > 1
      ymd = values.first.scan(/\d+/).map(&:to_i)
      tn = Time.new(
        (ymd[0]<100 ? 2000 + ymd[0] : ymd[0]),
        (ymd.size>1 ? ymd[1] : 1),
        (ymd.size>2 ? ymd[2] : 1)
      )
      values.shift
    end
    $options[:send_time]  = Time.parse(values.first, tn)
  end
end



ARGV.compact!

if ARGV.empty?
  $errprs << "No destination phone numbers were provided."
else
  ARGV.each do |v|
    phone_number = v.gsub('-','').gsub('.','')
    unless valid_phone_number? phone_number
      $errors << "Invalid phone number (must be 10 digits): #{v}"
      next
    end
    $options[:phone_numbers] << phone_number
  end
end

abort_if_errors

# Gary's 6152688522

require 'twilio-ruby'
require 'phony'

$client = Twilio::REST::Client.new $twilio.acct_sid, $twilio.auth

######################################################
# Local methods

class Time
  def before?(a_time)
    (self <=> a_time) < 0
  end
  def after?(a_time)
    (self <=> a_time) > 0
  end
  # a_string is expected to be in the form of hours[:minutes[:seconds]]
  # where hours is 0..23 minutes is 0..59 seconds is 0..59
  def self.parse(a_string)
    hms = a_string.scan(/\d+/).map(&:to_i)
    tn = now
    initialize(tn.year, tn.month, tn.day,
      hms[0], (hms.size>1 ? hms[1] : 0), (hms.size>2 ? hms[2] : 0))
  end
end # class Time

def list_applications
  puts ">"*15
  apps = $client.account.applications.list
  apps.each do |app|
    pp app
    pp app.methods.sort
    [:account_sid,
     :api_version,
     :date_created,
     :date_updated,
     :friendly_name,
     :message_status_callback,
     :sid,
     :sms_fallback_method,
     :sms_fallback_url,
     :sms_method,
     :sms_status_callback,
     :sms_url,
     :status_callback,
     :status_callback_method,
     :uri,
     :voice_caller_id_lookup,
     :voice_fallback_method,
     :voice_fallback_url,
     :voice_method,
     :voice_url].each do |m|
      v = app.send(m)
      puts "#{m} => #{v}"
    end
  end
  puts "<"*15
end # def list_applications


def new_app

end # def new_app


def update_app(app_sid=$twilio.app_sid)
  app = $client.account.applications.get(app_sid)
  app.update(
    :voice_url  => "http://demo.twilio.com/docs/voice.xml",
    :sms_url    => "http://demo.twilio.com/docs/sms.xml"
  )
end # def update_app(app_sid=$twilio.app_sid)


def delete_app(app_sid=$twilio.app_sid)

end # def delete_app(app_sid=$twilio.app_sid)



# Convert domestic phone numbers into international format as used
# by Twilio
# SMELL: USA only
def convert_phone_number_to_e164(phone_number, country_code='1')
  phone_number = (country_code + phone_number) if 10 == phone_number.size
  Phony.format(
      phone_number,
      :format => :international,
      :spaces => ''
  ).gsub(/\s+/, "") # Phony won't remove all spaces
end


# SMELL: this format is domestic numbers only
def format_phone_number(phone_number)
  return(phone_number) unless valid_phone_number? phone_number
  "(#{phone_number[0,3]}) #{phone_number[3,3]}-#{phone_number[6,4]}"
end


def validate_outgoing_phone_number(phone_number)
  return(nil) unless auto_validate?
  response = $client.account.outgoing_caller_ids.create(
    :phone_number => convert_phone_number_to_e164(phone_number)
  )
  puts response.validation_code
end

def disable_outgoing_phone_number(phone_number)
  response = $client.account.outgoing_caller_ids.list(
    :phone_number => convert_phone_number_to_e164(phone_number)
  )
  callerid = response[0]
  callerid.delete()
end

def send_voice_message_to (phone_number)
  puts "sending voice message to #{format_phone_number phone_number} ..." if verbose?
  begin
    outgoing_call = $client.account.calls.make(
        convert_phone_number_to_e164($twilio.phone),  # from
        convert_phone_number_to_e164(phone_number),   # to
        # BAD because of POST event to AWS/S3 Nenv.voice_xml_url
        # Nenv.echo_url
        Nenv.simple_message_url                            # url
      )
  #rescue Twilio::REST::RequestError
  #  puts "#{phone_number} is unverified for the trial Twilio account."
  #  validate_outgoing_phone_number(phone_number) if auto_validate?
  end
end # def send_voice_message_to (phone_number)


def send_sms_message_to (phone_number)
  puts "sending SMS message to #{phone_number} ..." if verbose?
  begin
    outgoing_message = $client.account.messages.create({
                                :to   => convert_phone_number_to_e164(phone_number),
                                :from => convert_phone_number_to_e164($twilio.phone),
                                :body => "The Upper Room Though for the Day: #{Nenv.tftd}",
                              })
  rescue Twilio::REST::RequestError
    puts "#{phone_number} is unverified for the trial Twilio account."
    validate_outgoing_phone_number(phone_number) if auto_validate?
  end
end # def send_sms_message_to (phone_number)


def send_mms_message_to (phone_number)
  puts "sending MMS message to #{format_phone_number phone_number} ..." if verbose?
  begin
    outgoing_message = $client.account.messages.create({
                                :to   => convert_phone_number_to_e164(phone_number),
                                :from => convert_phone_number_to_e164($twilio.phone),
                                :body => Nenv.tftd,
                                :media_url => "http://s3.amazonaws.com/images.upperroom.org/devotional/en/issue_covers/slideshow/175.png?1418924817"
                              })
  rescue Twilio::REST::RequestError
    puts "#{phone_number} is unverified for the trial Twilio account."
    validate_outgoing_phone_number(phone_number) if auto_validate?
  end
end # def send_mms_message_to (phone_number)





######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

puts
pp $options
puts

list_applications if list?

puts

unless $options[:send_time].nil?
  puts Time.now
  puts $options[:send_time]
  while Time.now.before? $options[:send_time]
    sleep 1
    puts Time.now
  end
end

$options[:phone_numbers].each do |phone_number|
  if disable?
    disable_outgoing_phone_number phone_number
    next
  end
  send_voice_message_to(phone_number)  if voice?
  send_sms_message_to(phone_number)    if sms?
  send_mms_message_to(phone_number)    if mms?
end
