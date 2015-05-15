require 'twilio-ruby'

TWILIO_ACCOUNT_SID  = ENV['TWILIO_ACCOUNT_SID']
TWILIO_AUTH_TOKEN   = ENV['TWILIO_AUTH_TOKEN'] || ENV['TWILIO_AUTH']

def valid_phone_number?(phone_number)
  lookup_client = Twilio::REST::LookupsClient.new(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
  begin
    response = lookup_client.phone_numbers.get(phone_number)
    response.phone_number #if invalid, throws an exception. If valid, no problems.
    return true
  rescue => e
    if e.code == 20404
      return false
    else
      raise e
  end
end
