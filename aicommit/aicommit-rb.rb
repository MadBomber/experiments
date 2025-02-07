#!/usr/bin/env ruby
# aicommit-rb.rb
#
# TODO:   gh repo view --json isPrivate -q '.isPrivate'
#

require 'optparse'
require './git_diff'
require './commit_message_generator'
require './style_guide'

options = {
  amend: false,
  context: [],
  dry: false,
  model: 'llama3.3',
  provider: nil,
  openai_base_url: 'https://api.openai.com/v1',
  openai_key: ENV.fetch('OPENAI_API_KEY', 'your_actual_openai_key_here'),
  save_key: false
}

OptionParser.new do |opts|
  opts.banner = "Usage: aicommit-rb [options] [ref]"

  opts.on("-a", "--amend", "Amend the last commit") do
    options[:amend] = true
  end

  opts.on("-cCONTEXT", "--context=CONTEXT", "Extra context beyond the diff") do |context|
    options[:context] << context
  end

  opts.on("-d", "--dry", "Dry run the command") do
    options[:dry] = true
  end

  opts.on("-mMODEL", "--model=MODEL", "The model to use") do |model|
    options[:model] = model
  end

  opts.on("--openai-base-url=URL", "The base URL for the OpenAI API") do |url|
    options[:openai_base_url] = url
  end

  opts.on("--openai-key=KEY", "The OpenAI API key to use") do |key|
    options[:openai_key] = key
  end

  opts.on("--save-key", "Save the OpenAI API key to configuration") do
    options[:save_key] = true
  end

  opts.on("--provider=PROVIDER", "Specify the provider") do |provider|
    options[:provider] = provider
  end
  opts.on("--version", "Show version") do
    puts "aicommit-rb version 0.1.0"
    exit
  end
end.parse!

# Set API key environment variable if provider is valid
if options[:provider]
  valid_providers = AiClient.providers
  if valid_providers.include?(options[:provider])
    api_key_env = "
    api_key_env = "#{options[:provider].upcase}_API_KEY"
    options[:openai_key] = ENV.fetch(api_key_env, 'your_actual_openai_key_here')
  else
    puts "Invalid provider specified. Valid providers are: #{valid_providers.join(', ')}"
    exit 1
  end
end

# Handle saving OpenAI API key if --save-key is specified
if options[:save_key]
  # Implementation to save the key
  puts "API key saved to configuration."
  exit
end

# Retrieve the commit reference if provided
commit_ref = ARGV.shift

# Set up directories and styles
dir = Dir.pwd
diff_generator = AicommitRb::GitDiff.new(dir: dir, commit_hash: commit_ref, amend: options[:amend])
diff = diff_generator.generate_diff

style_guide = AicommitRb::StyleGuide.load(dir)

# Set the OpenAI model and key
generator = AicommitRb::CommitMessageGenerator.new(api_key: options[:openai_key], model: options[:model], max_tokens: 1000)

# Generate the commit message, considering the context and other options
commit_message = generator.generate(diff, style_guide)

puts commit_message unless options[:dry]

