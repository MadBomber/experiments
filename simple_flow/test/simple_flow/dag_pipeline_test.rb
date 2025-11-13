# frozen_string_literal: true

require "test_helper"

module SimpleFlow
  class DagPipelineTest < Minitest::Test
    def setup
      @initial_result = Result.new(0)
    end

    def test_simple_dependency_chain
      pipeline = DagPipeline.new do
        step :step_a, ->(r) { r.continue(r.value + 1) }
        step :step_b, ->(r) { r.continue(r.value * 2) }, depends_on: :step_a
        step :step_c, ->(r) { r.continue(r.value + 10) }, depends_on: :step_b
      end

      result = pipeline.call(@initial_result)
      # (0 + 1) * 2 + 10 = 12
      assert_equal 12, result.value
    end

    def test_parallel_dependencies
      execution_order = []

      pipeline = DagPipeline.new do
        step :root, ->(r) {
          execution_order << :root
          r.continue(r.value + 1)
        }

        step :branch_a, ->(r) {
          execution_order << :branch_a
          r.continue(r.value)
        }, depends_on: :root

        step :branch_b, ->(r) {
          execution_order << :branch_b
          r.continue(r.value)
        }, depends_on: :root

        step :merge, ->(r) {
          execution_order << :merge
          r.continue(r.value + 10)
        }, depends_on: [:branch_a, :branch_b]
      end

      result = pipeline.call(@initial_result)

      # Root runs first
      assert_equal :root, execution_order.first
      # Merge runs last
      assert_equal :merge, execution_order.last
      # Branches run in some order between root and merge
      assert execution_order.include?(:branch_a)
      assert execution_order.include?(:branch_b)

      assert_equal 11, result.value
    end

    def test_sorted_steps
      pipeline = DagPipeline.new do
        step :c, ->(r) { r }, depends_on: [:a, :b]
        step :b, ->(r) { r }, depends_on: :a
        step :a, ->(r) { r }
      end

      sorted = pipeline.sorted_steps

      # a must come before b
      assert sorted.index(:a) < sorted.index(:b)
      # b must come before c
      assert sorted.index(:b) < sorted.index(:c)
      # a must come before c
      assert sorted.index(:a) < sorted.index(:c)
    end

    def test_parallel_groups
      pipeline = DagPipeline.new do
        step :a, ->(r) { r }
        step :b, ->(r) { r }, depends_on: :a
        step :c, ->(r) { r }, depends_on: :a
        step :d, ->(r) { r }, depends_on: [:b, :c]
      end

      groups = pipeline.parallel_groups

      # First group should only be :a
      assert_equal [:a], groups[0]
      # Second group should be :b and :c (can run in parallel)
      assert_equal [:b, :c], groups[1].sort
      # Third group should be :d
      assert_equal [:d], groups[2]
    end

    def test_call_async
      execution_order = []

      pipeline = DagPipeline.new do
        step :root, ->(r) {
          execution_order << :root
          r.continue(r.value + 1)
        }

        step :parallel_a, ->(r) {
          execution_order << :parallel_a
          r.continue(r.value)
        }, depends_on: :root

        step :parallel_b, ->(r) {
          execution_order << :parallel_b
          r.continue(r.value)
        }, depends_on: :root

        step :merge, ->(r) {
          execution_order << :merge
          r.continue(r.value + 10)
        }, depends_on: [:parallel_a, :parallel_b]
      end

      result = pipeline.call(@initial_result)

      assert_equal 11, result.value
      # Root should be first
      assert_equal :root, execution_order.first
      # Merge should be last
      assert_equal :merge, execution_order.last
      # parallel_a and parallel_b should be in the middle (concurrent)
      assert execution_order.include?(:parallel_a)
      assert execution_order.include?(:parallel_b)
    end

    def test_circular_dependency_detection
      pipeline = DagPipeline.new do
        step :a, ->(r) { r }, depends_on: :b
        step :b, ->(r) { r }, depends_on: :a
      end

      assert_raises CircularDependencyError do
        pipeline.call(@initial_result)
      end
    end

    def test_subgraph
      pipeline = DagPipeline.new do
        step :a, ->(r) { r.continue(r.value + 1) }
        step :b, ->(r) { r.continue(r.value * 2) }, depends_on: :a
        step :c, ->(r) { r.continue(r.value + 10) }, depends_on: :b
        step :unrelated, ->(r) { r.continue(999) }
      end

      sub = pipeline.subgraph(:c)
      result = sub.call(@initial_result)

      # Should include a, b, c but not unrelated
      # (0 + 1) * 2 + 10 = 12
      assert_equal 12, result.value
    end

    def test_merge_pipelines
      pipeline1 = DagPipeline.new do
        step :a, ->(r) { r.continue(r.value + 1) }
        step :b, ->(r) { r.continue(r.value * 2) }, depends_on: :a
      end

      pipeline2 = DagPipeline.new do
        step :c, ->(r) { r.continue(r.value + 10) }, depends_on: :b
      end

      merged = pipeline1.merge(pipeline2)
      result = merged.call(@initial_result)

      # (0 + 1) * 2 + 10 = 12
      assert_equal 12, result.value
    end

    def test_no_dependencies
      pipeline = DagPipeline.new do
        step :a, ->(r) { r.continue(r.value + 1) }
        step :b, ->(r) { r.continue(r.value + 2) }
        step :c, ->(r) { r.continue(r.value + 3) }
      end

      # All steps should be in same parallel group
      groups = pipeline.parallel_groups
      assert_equal 1, groups.size
      assert_equal [:a, :b, :c].sort, groups[0].sort
    end

    def test_halt_stops_execution
      pipeline = DagPipeline.new do
        step :a, ->(r) { r.continue(r.value + 1) }
        step :b, ->(r) { r.halt(r.value * 2) }, depends_on: :a
        step :c, ->(r) { r.continue(r.value + 10) }, depends_on: :b
      end

      result = pipeline.call(@initial_result)

      # Should stop at b: (0 + 1) * 2 = 2
      assert_equal 2, result.value
      refute result.continue?
    end

    def test_context_from_dependencies
      step_b_context = nil

      pipeline = DagPipeline.new do
        step :a, ->(r) {
          r.with_context(:a_value, 100).continue(r.value + 1)
        }

        step :b, ->(r) {
          # Capture the context to verify later
          step_b_context = r.context
          r.continue(r.value)
        }, depends_on: :a
      end

      result = pipeline.call(@initial_result)

      assert result.success?
      # Should have access to context from dependency a (prefixed with step name)
      assert step_b_context.key?(:a_a_value), "Expected :a_a_value in context, got: #{step_b_context.keys.inspect}"
      assert_equal 100, step_b_context[:a_a_value]
    end

    def test_error_in_async_execution
      pipeline = DagPipeline.new do
        step :root, ->(r) { r.continue(r.value + 1) }

        step :will_fail, ->(r) {
          raise StandardError, "Intentional failure"
        }, depends_on: :root

        step :will_succeed, ->(r) {
          r.continue(r.value * 2)
        }, depends_on: :root

        step :depends_on_both, ->(r) {
          r.continue(r.value + 10)
        }, depends_on: [:will_fail, :will_succeed]
      end

      result = pipeline.call(@initial_result)

      refute result.continue?
      assert result.failure?
    end

    def test_step_if_with_dependencies
      pipeline = DagPipeline.new do
        step :a, ->(r) { r.continue(r.value + 1) }

        step_if :conditional,
                ->(r) { r.value > 5 },
                ->(r) { r.continue(r.value * 10) },
                depends_on: :a

        step :c, ->(r) { r.continue(r.value + 100) }, depends_on: :conditional
      end

      # When condition is false (value = 1)
      result1 = pipeline.call(Result.new(0))
      assert_equal 101, result1.value # (0 + 1) + 100

      # When condition is true (value = 10)
      result2 = pipeline.call(Result.new(9))
      assert_equal 200, result2.value # (9 + 1) * 10 + 100
    end
  end
end
