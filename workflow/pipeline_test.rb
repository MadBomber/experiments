require 'minitest/autorun'
require_relative 'simple_flow' # Assuming your SimpleFlow module code is saved in simple_flow.rb

module SimpleFlow
  class Result
    attr_accessor :value, :continue

    def initialize(value = nil, continue: true)
      @value = value
      @continue = continue
    end

    def continue?
      @continue
    end

    def call(input)
      yield(input, self) if block_given?
      self
    end
  end
end

class TestSimpleFlowPipeline < Minitest::Test
  def test_pipeline_with_no_step
    pipeline = SimpleFlow::Pipeline.new
    result = SimpleFlow::Result.new
    assert_equal result, pipeline.call(result)
  end

  def test_pipeline_with_one_step
    pipeline = SimpleFlow::Pipeline.new do
      step ->(result) { result.call { |input, res| res.value = "processed"; res } }
    end
    result = pipeline.call(SimpleFlow::Result.new)
    assert_equal "processed", result.value
  end

  def test_pipeline_with_multiple_steps
    pipeline = SimpleFlow::Pipeline.new do
      step ->(result) { result.call { |_, res| res.value = 1; res } }
      step ->(result) { result.call { |_, res| res.value += 1; res } }
    end
    result = pipeline.call(SimpleFlow::Result.new)
    assert_equal 2, result.value
  end
  
  def test_pipeline_with_middleware
    middleware = ->(callable) {
      ->(result) {
        modified_result = callable.call(result)
        modified_result.call { |_, res| res.value *= 2; res }
      }
    }

    pipeline = SimpleFlow::Pipeline.new do
      use_middleware middleware
      step ->(result) { result.call { |_, res| res.value = 1; res } }
    end
    result = pipeline.call(SimpleFlow::Result.new)
    assert_equal 2, result.value
  end
  
  def test_pipeline_stops_when_continue_is_false
    pipeline = SimpleFlow::Pipeline.new do
      step ->(result) { result.call { |_, res| res.continue = false } }
      step ->(result) { result.call { |_, res| res.value = "should not process"; res } }
    end
    result = pipeline.call(SimpleFlow::Result.new)
    assert_nil result.value, "Pipeline did not stop as expected"
  end
end
