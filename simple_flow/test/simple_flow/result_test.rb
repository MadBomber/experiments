# frozen_string_literal: true

require "test_helper"

module SimpleFlow
  class ResultTest < Minitest::Test
    def setup
      @result = Result.new(42)
    end

    def test_initialization
      assert_equal 42, @result.value
      assert_equal({}, @result.context)
      assert_equal({}, @result.errors)
      assert @result.continue?
    end

    def test_with_context
      new_result = @result.with_context(:user_id, 123)

      assert_equal 123, new_result.context[:user_id]
      assert_equal 42, new_result.value
      assert new_result.continue?

      # Original should be unchanged
      assert_equal({}, @result.context)
    end

    def test_merge_context
      new_result = @result.merge_context(user_id: 123, session_id: 456)

      assert_equal 123, new_result.context[:user_id]
      assert_equal 456, new_result.context[:session_id]
    end

    def test_with_error
      new_result = @result.with_error(:validation, "Invalid input", severity: :error)

      assert_equal 1, new_result.errors[:validation].size
      error = new_result.errors[:validation].first
      assert_instance_of ExecutionError, error
      assert_equal "Invalid input", error.message
      assert_equal :error, error.severity

      # Original should be unchanged
      assert_equal({}, @result.errors)
    end

    def test_halt_immutability
      # This tests the FIX for the immutability bug
      halted = @result.halt

      refute halted.continue?
      assert @result.continue?, "Original result should still have continue=true"

      # Test halt with new value
      halted_with_value = @result.halt(100)
      assert_equal 100, halted_with_value.value
      refute halted_with_value.continue?
      assert_equal 42, @result.value, "Original result value unchanged"
    end

    def test_continue
      new_result = @result.continue(100)

      assert_equal 100, new_result.value
      assert new_result.continue?
      assert_equal 42, @result.value, "Original result unchanged"
    end

    def test_success_predicate
      assert @result.success?

      with_error = @result.with_error(:test, "error")
      refute with_error.success?

      halted = @result.halt
      refute halted.success?
    end

    def test_failure_predicate
      refute @result.failure?

      with_error = @result.with_error(:test, "error", severity: :error)
      assert with_error.failure?

      halted = @result.halt
      assert halted.failure?
    end

    def test_critical_errors
      result_with_warning = @result.with_error(:test, "warning", severity: :warning)
      refute result_with_warning.critical_errors?

      result_with_critical = @result.with_error(:test, "critical", severity: :critical)
      assert result_with_critical.critical_errors?
    end

    def test_all_errors
      result = @result
        .with_error(:validation, "Error 1")
        .with_error(:validation, "Error 2")
        .with_error(:processing, "Error 3")

      assert_equal 3, result.all_errors.size
      assert_equal 2, result.errors[:validation].size
      assert_equal 1, result.errors[:processing].size
    end

    def test_warnings
      result = @result
        .with_error(:test, "warning", severity: :warning)
        .with_error(:test, "error", severity: :error)

      warnings = result.warnings
      assert_equal 1, warnings.size
      assert warnings.first.warning?
    end

    def test_to_h
      result = @result
        .with_context(:user_id, 123)
        .with_error(:test, "error")

      hash = result.to_h

      assert_equal 42, hash[:value]
      assert_equal 123, hash[:context][:user_id]
      assert hash[:errors].key?(:test)
      assert_equal true, hash[:continue]
    end

    def test_to_s
      result_str = @result.to_s
      assert_includes result_str, "SUCCESS"
      assert_includes result_str, "42"

      halted_str = @result.halt.to_s
      assert_includes halted_str, "FAILURE"
    end
  end
end
