#!/usr/bin/env ruby
# File: json_format_error.rb*

require 'amazing_print'
require 'json'

require 'omniai'
require 'omniai/openai'

client = OmniAI::OpenAI::Client.new(timeout: {
  read: 2, # i.e. 2 seconds
  write: 3, # i.e. 3 seconds
  connect: 4, # i.e. 4 seconds
})

messages = [
  {
    role: OmniAI::Chat::Role::SYSTEM,
    # TDV: had to add the word  vvvv to make it work
    content: 'You are a helpful JSON assistant with an expertise in geography.',
  },
  'What is the capital of Canada?'
]

completion = client.chat(messages, model: 'gpt-4o-2024-05-13', temperature: 0.7, format: :json)

result = JSON.parse completion.data['choices'][0].dig('message', 'content')

ap result

__END__

20:34:01 3.4.0preview1 master nibiru:OmniAI $ ./json_format_error.rb
/Users/dewayne/.rbenv/versions/3.4.0-preview1/lib/ruby/gems/3.4.0+0/gems/omniai-1.3.1/lib/omniai/chat.rb:63:in 'OmniAI::Chat#process!': status=#<HTTP::Response::Status 400 Bad Request> headers=#<HTTP::Headers {"Date"=>"Sun, 30 Jun 2024 01:34:04 GMT", "Content-Type"=>"application/json", "Content-Length"=>"219", "Connection"=>"keep-alive", "openai-organization"=>"user-ifrawzdluvy3lyawe5koawx0", "openai-processing-ms"=>"14", "openai-version"=>"2020-10-01", "strict-transport-security"=>"max-age=31536000; includeSubDomains", "x-ratelimit-limit-requests"=>"5000", "x-ratelimit-limit-tokens"=>"600000", "x-ratelimit-remaining-requests"=>"4999", "x-ratelimit-remaining-tokens"=>"599958", "x-ratelimit-reset-requests"=>"12ms", "x-ratelimit-reset-tokens"=>"4ms", "x-request-id"=>"req_91f056cd34313bee75c0ea11b8d19cf2", "CF-Cache-Status"=>"DYNAMIC", "Set-Cookie"=>["__cf_bm=Ea_qGz9Y75xOQS82_nT5poW5ocAiJ0D5YMC3NnSF9g4-1719711244-1.0.1.1-JzGJM4afR1ch_lkAyC3IGngEFs1ePq7m6lCyRzmaF2xoP_mGBCl6zr7n1YOfpcIOQniNN8lkxmOiIZ0Xr4tyKA; path=/; expires=Sun, 30-Jun-24 02:04:04 GMT; domain=.api.openai.com; HttpOnly; Secure; SameSite=None", "_cfuvid=MZTJV2HTUg8E1Ni9hHPC.6KwGo70Mhgqzp6CHyxY2vI-1719711244072-0.0.1.1-604800000; path=/; domain=.api.openai.com; HttpOnly; Secure; SameSite=None"], "Server"=>"cloudflare", "CF-RAY"=>"89ba6969da836bf2-DFW", "alt-svc"=>"h3=\":443\"; ma=86400"}> body={ (OmniAI::HTTPError)
  "error": {
    "message": "'messages' must contain the word 'json' in some form, to use 'response_format' of type 'json_object'.",
    "type": "invalid_request_error",
    "param": "messages",
    "code": null
  }
}
  from /Users/dewayne/.rbenv/versions/3.4.0-preview1/lib/ruby/gems/3.4.0+0/gems/omniai-1.3.1/lib/omniai/chat.rb:41:in 'OmniAI::Chat.process!'
  from /Users/dewayne/.rbenv/versions/3.4.0-preview1/lib/ruby/gems/3.4.0+0/gems/omniai-openai-1.3.3/lib/omniai/openai/client.rb:73:in 'OmniAI::OpenAI::Client#chat'
  from ./json_format_error.rb:20:in '<main>'

