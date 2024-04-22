#
# SimpleFlow is a modular, configurable processing framework designed for constructing and
# managing sequences of operations in a streamlined and efficient manner. It allows for the easy
# integration of middleware components to augment functionality, such as logging and
# instrumentation, ensuring that actions within the pipeline are executed seamlessly. By
# defining steps as callable objects, SimpleFlow facilitates the customized processing of data,
# offering granular control over the flow of execution and enabling conditional continuation
# based on the outcome of each step. This approach makes SimpleFlow ideal for complex workflows
# where the orchestration of tasks, error handling, and context management are crucial.
#

require 'delegate'
require 'logger'

require_relative 'pipeline'
require_relative 'result'
require_relative 'middleware'
require_relative 'step_tracker'

module SimpleFlow
end

__END__

require_relative './simple_flow'

# Usage example
pipeline = SimpleFlow::Pipeline.new do
  use_middleware SimpleFlow::MiddleWare::Instrumentation, api_key: '1234'
  use_middleware SimpleFlow::MiddleWare::Logging
  step ->(result) { puts "Processing: #{result.value}"; result }
  step ->(result) { result.continue(result.value + 1) }
end

initial_result = SimpleFlow::Result.new(0)
result = pipeline.call(initial_result)
puts "Final Result: #{result.value}"

