require 'minitest/autorun'
require_relative 'result' # Update with actual path

module SimpleFlow
  class ResultTest < Minitest::Test
    def test_initialize
      result = Result.new(10)
      assert_equal 10, result.value
      assert_empty result.context
      assert_empty result.errors
    end

    def test_with_context
      original = Result.new('orig')
      updated = original.with_context(:user, 1)

      refute_equal original.object_id, updated.object_id
      assert_equal 1, updated.context[:user]
    end

    def test_with_error
      original = Result.new('orig')
      updated = original.with_error(:validation, 'Invalid')

      refute_equal original.object_id, updated.object_id
      assert_equal ['Invalid'], updated.errors[:validation]
    end

    def test_halt
      result = Result.new('keep')

      halted = result.halt
      assert_equal false, halted.continue?

      halted_with_value = result.halt('stop')
      refute_equal result.value, halted_with_value.value
      assert_equal 'stop', halted_with_value.value
      assert_equal false, halted_with_value.continue?
    end

    def test_continue
      result = Result.new('start')
      continued = result.continue('go')

      assert_equal true, continued.continue?
      assert_equal 'go', continued.value
    end

    def test_continue_question
      result = Result.new('data')
      assert_equal true, result.continue?

      halted = result.halt
      refute_equal true, halted.continue?
    end
  end
end

