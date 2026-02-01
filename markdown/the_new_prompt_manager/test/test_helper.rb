# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../pm'

FIXTURES = File.expand_path('fixtures', __dir__)

def fixture(name)
  File.join(FIXTURES, name)
end
