require 'minitest/autorun'
require_relative '../commit_message_generator'

module AicommitRb
  class TestCommitMessageGenerator < Minitest::Test
    def setup
      @generator = CommitMessageGenerator.new(api_key: 'test_key', model: 'default', max_tokens: 1000)
    end

    def test_generate
      diff = 'sample diff'
      style_guide = 'sample style guide'
      result = @generator.generate(diff, style_guide)
      assert result.is_a?(String) # Example test
    end
  end
end