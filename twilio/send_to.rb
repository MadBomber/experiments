#!/usr/bin/env ruby
# encoding: utf-8
##########################################################
###
##  File: send_to.rb
##  Desc: Send either a voice message or an SMS to a phone number
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'debug_me'
require 'nenv'

$twilio = Nenv :twilio

Nenv.tftd = "How well do I imitate God in word and deed?"

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

  phone_number+         The mobil phone number destination(s)

NOTE:

  For the trial account only verified phone numbers can be reached.
    Gary:     615-268-8522

  Verified Numbers are:
    Dewayne:  817-905-1687
    Jorge:    615-828-5975

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

%w[ --validate ].each do |param|
  if ARGV.include? param
    $options[:auto_validate]  = true
    ARGV[ ARGV.index(param) ] = nil
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

$client = Twilio::REST::Client.new $twilio.acct_sid, $twilio.auth

######################################################
# Local methods

def format_phone_number(phone_number)
  return(phone_number) unless valid_phone_number? phone_number
  "(#{phone_number[0,3]}) #{phone_number[3,3]}-#{phone_number[6,4]}"
end


def validate_outgoing_phone_number(phone_number)
  return(nil) unless auto_validate?
  response = $client.account.outgoing_caller_ids.create(:phone_number => "+1#{phone_number}")
  puts response.validation_code
end


def send_voice_message_to (phone_number)
  puts "sending voice message to #{format_phone_number phone_number} ..." if verbose?
  begin
    outgoing_call = $client.account.calls.create({
        :to   => phone_number,
        :from => $twilio.phone,
        :url  => "http://twimlets.com/holdmusic?Bucket=com.twilio.music.ambient"})
  rescue Twilio::REST::RequestError
    puts "#{phone_number} is unverified for the trial Twilio account."
    validate_outgoing_phone_number(phone_number) if auto_validate?
  end

end # def send_voice_message_to (phone_number)


def send_sms_message_to (phone_number)
  puts "sending SMS message to #{phone_number} ..." if verbose?

  begin
    outgoing_message = $client.account.messages.create({
                                    :to => "+1#{phone_number}",
                                    :from => "+1#{$twilio.phone}",
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
                                    :to => "+1#{phone_number}",
                                    :from => "+1#{$twilio.phone}",
                                    :body => "Though for the Day: #{Nenv.tftd}",
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

pp $options

$options[:phone_numbers].each do |phone_number|
  send_voice_message_to(phone_number)  if voice?
  send_sms_message_to(phone_number)    if sms?
  send_mms_message_to(phone_number)    if mms?
end
