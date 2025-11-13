# frozen_string_literal: true

require "test_helper"

module SimpleFlow
  class PipelineTest < Minitest::Test
    def setup
      @initial_result = Result.new(1)
    end

    def test_basic_pipeline_execution
      pipeline = Pipeline.new do
        step :add_ten, ->(result) { result.continue(result.value + 10) }
        step :multiply_by_two, ->(result) { result.continue(result.value * 2) }
      end

      result = pipeline.call(@initial_result)

      assert_equal 22, result.value
      assert result.continue?
    end

    def test_pipeline_with_halt
      pipeline = Pipeline.new do
        step :add_ten, ->(result) { result.continue(result.value + 10) }
        step :halt_step, ->(result) { result.halt(result.value * 2) }
        step :should_not_run, ->(result) { result.continue(999) }
      end

      result = pipeline.call(@initial_result)

      assert_equal 22, result.value
      refute result.continue?
    end

    def test_middleware_integration
      executed = []

      test_middleware = lambda do |callable|
        lambda do |result|
          executed << :before
          result = callable.call(result)
          executed << :after
          result
        end
      end

      pipeline = Pipeline.new do
        use_middleware test_middleware
        step :test, ->(result) { result.continue(result.value) }
      end

      pipeline.call(@initial_result)

      assert_equal [:before, :after], executed
    end

    def test_conditional_step
      pipeline = Pipeline.new do
        step_if :conditional,
                ->(r) { r.value > 5 },
                ->(r) { r.continue(r.value * 10) }

        step :always_runs, ->(r) { r.continue(r.value + 1) }
      end

      # When condition is false (1 > 5 is false)
      result1 = pipeline.call(Result.new(1))
      assert_equal 2, result1.value
      assert result1.context[:conditional_skipped]

      # When condition is true (10 > 5 is true)
      result2 = pipeline.call(Result.new(10))
      assert_equal 101, result2.value
    end

    def test_pipeline_composition
      pipeline1 = Pipeline.new(name: :first) do
        step :add_one, ->(r) { r.continue(r.value + 1) }
      end

      pipeline2 = Pipeline.new(name: :second) do
        step :multiply_two, ->(r) { r.continue(r.value * 2) }
      end

      composed = pipeline1 >> pipeline2

      result = composed.call(Result.new(5))
      assert_equal 12, result.value # (5 + 1) * 2
    end

    def test_subpipeline
      pipeline = Pipeline.new do
        step :step_a, ->(r) { r.continue(r.value + 1) }
        step :step_b, ->(r) { r.continue(r.value * 2) }
        step :step_c, ->(r) { r.continue(r.value + 10) }
      end

      sub = pipeline.subpipeline(:step_a, :step_c)

      result = sub.call(Result.new(5))
      # Should only run step_a and step_c
      assert_equal 16, result.value # (5 + 1) + 10, skipping step_b
    end

    def test_step_names
      pipeline = Pipeline.new do
        step :first, ->(r) { r }
        step :second, ->(r) { r }
        step :third, ->(r) { r }
      end

      assert_equal [:first, :second, :third], pipeline.step_names
    end

    def test_find_step
      step_callable = ->(r) { r.continue(42) }
      pipeline = Pipeline.new do
        step :findme, step_callable
      end

      found = pipeline.find_step(:findme)
      assert found
    end

    def test_error_handling_in_steps
      pipeline = Pipeline.new do
        step :will_error, ->(r) { raise StandardError, "Test error" }
        step :should_not_run, ->(r) { r.continue(999) }
      end

      result = pipeline.call(@initial_result)

      refute result.continue?
      assert result.failure?
      assert result.errors.key?(:step_error)
    end

    def test_context_propagation
      pipeline = Pipeline.new do
        step :add_context, ->(r) { r.with_context(:step1_data, "data").continue(r.value) }
        step :read_context, ->(r) {
          assert_equal "data", r.context[:step1_data]
          r.continue(r.value)
        }
      end

      result = pipeline.call(@initial_result)
      assert result.success?
      assert_equal "data", result.context[:step1_data]
    end

    def test_pipeline_size
      pipeline = Pipeline.new do
        step :one, ->(r) { r }
        step :two, ->(r) { r }
        step :three, ->(r) { r }
      end

      assert_equal 3, pipeline.size
    end

    def test_to_s
      pipeline = Pipeline.new(name: :test_pipeline) do
        step :one, ->(r) { r }
      end

      str = pipeline.to_s
      assert_includes str, "test_pipeline"
      assert_includes str, "1 steps"
    end
  end
end
