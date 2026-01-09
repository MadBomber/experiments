# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development, :test do
  gem "debug_me"
  gem "minitest"
  gem "rake"
  gem "rubocop"
  gem "yard"
end

group :development do
  # Optional LLM clients
  gem "ruby_llm", require: false
  gem "ruby-openai", require: false
  gem "anthropic", require: false
end
