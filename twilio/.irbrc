require 'twilio-ruby'
require 'phony'
require 'nenv'

Nenv.tftd = "How well do I imitate God in word and deed?"
Nenv.voice_url = "https://s3.amazonaws.com/voice.devotional.upperroom.org/en/20140401_en.mp3"
Nenv.voice_xml_url = "https://s3.amazonaws.com/voice.devotional.upperroom.org/en/20140401_en.xml"


$twilio = Nenv :twilio

$client = Twilio::REST::Client.new $twilio.acct_sid, $twilio.auth

$twiml = Twilio::TwiML::Response.new do |r|
    r.Play Nenv.voice_url
    r.Say 'If you have enjoyed receiving this devotional, please consider a subscription to The Upper Room.  Thank you and may God bless your day.'
end.text

