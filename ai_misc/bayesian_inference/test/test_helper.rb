# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "bayesian_inference"
require "minitest/autorun"
require "debug_me"

# Suppress debug_me output during tests unless DEBUG env var is set
unless ENV['DEBUG']
  module DebugMe
    def debug_me(*args, &block)
      # No-op during tests
    end
  end
end
