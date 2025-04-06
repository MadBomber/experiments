#!/usr/bin/env ruby

require 'monkeyspaw'

MonkeysPaw.configure do |config|
  config.port = 4567
  config.host = 'localhost'
end

# MonkeysPaw.use :gemini, model: :gemini_2_0_flash

# MonkeysPaw.use :openai, model: :gpt_4
# MonkeysPaw.use :anthropic, model: :claude_3_opus
# MonkeysPaw.use :mistral, model: :mistral_large

MonkeysPaw.pick_up!
