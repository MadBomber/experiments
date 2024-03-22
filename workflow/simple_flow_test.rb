require 'minitest/autorun'
require_relative 'simple_flow' # Make sure this points to the file where SimpleFlow module is defined.

module SimpleFlow
  class TestSimpleFlow < Minitest::Test
    def setup
      @pipeline = Pipeline.new do
        use_middleware MiddleWare::Instrumentation, api_key: 'test_key'
        step ->(result) { result.continue(result.value + 10) }
        step ->(result) { result.halt(result.value * 2) }
      end

      @initial_result = Result.new(1)
    end

    def test_pipeline_execution
      result = @pipeline.call(@initial_result)
      assert_equal 22, result.value, "Pipeline should process value correctly"
      assert result.continue?, "Result should not halt unexpectedly"
    end

    def test_middleware_integration
      executed_middlewares = []
      @pipeline = Pipeline.new do
        use_middleware ->(callable) {
          ->(result) {
            executed_middlewares << "Instrumentation"
            callable.call(result)
          }
        }
        step ->(result) { result }
      end
      @pipeline.call(@initial_result)
      assert_includes executed_middlewares, "Instrumentation", "Instrumentation middleware should execute"
    end

    def test_result_handling
      result = @pipeline.call(@initial_result)
      assert result.errors.empty?, "Result should have no errors"
      assert_equal({}, result.context, "Result context should remain unchanged")
    end

    def test_result_with_context_and_error
      result = @initial_result.with_context(:key, 'value')
                               .with_error(:error_key, 'An error occurred')
      
      assert_equal 'value', result.context[:key], "Context should include the new key-value pair"
      assert_includes result.errors[:error_key], 'An error occurred', "Errors should include the new error message"
    end

    def test_halt_execution
      @pipeline = Pipeline.new do
        step ->(result) { result.halt(0) }
        step ->(result) { result.continue(100) } # This should not execute
      end

      result = @pipeline.call(@initial_result)
      refute result.continue?, "Execution should halt after the first step"
      assert_equal 0, result.value, "Value should be updated to halt value"
    end
  end
end
