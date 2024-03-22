require 'delegate'

# This Ruby module is called SimpleFlow and it provides a simple workflow management utility. 
# The key component demonstrated here is the StepTracker class, which is used to track the 
# execution of steps within a workflow. This class utilizes the decorator pattern by inheriting 
# from SimpleDelegator, allowing it to wrap around any object that responds to #call, and 
# enhancing its behavior without modifying the original object's class.
module SimpleFlow
  
  ##
  # The StepTracker class serves as a wrapper around any callable object, typically representing
  # a step in a workflow. Its primary purpose is to execute the wrapped object's call method
  # and then decide what to do based on the outcome. If the result of the call indicates that 
  # the process can continue, it simply returns the result. However, if the process should halt, 
  # it enriches the result with additional context before returning it.
  #
  # This enables a mechanism for both executing steps in a workflow and conditionally handling
  # situations where a step decides the flow should not continue. The enriched context can then
  # be used downstream to understand why the flow was halted, and potentially take corrective action.
  #
  # Example usage:
  # 
  #  class ExampleStep
  #    def call(result)
  #      result.do_something
  #      if result.success?
  #        result.with_continue(true)
  #      else
  #        result.with_continue(false)
  #      end
  #    end
  #  end
  #
  #  result = SomeResult.new
  #  wrapped_step = SimpleFlow::StepTracker.new(ExampleStep.new)
  #  final_result = wrapped_step.call(result)
  #  
  #  if final_result.continue
  #    # proceed with workflow
  #  else
  #    # handle halted workflow
  #  end
  class StepTracker < SimpleDelegator
    
    # Calls the wrapped object's call method with the given result. Depending on the outcome 
    # of this call, it either returns the result as-is (to continue the workflow) or enriches 
    # the result with context indicating that this particular step is where the workflow was 
    # halted.
    # 
    # @param result [Object] The result object that is being passed through the workflow steps.
    # @return [Object] The modified result object, potentially enriched with additional context.
    def call(result)
      result = __getobj__.call(result)
      result.continue? ? result : result.with_context(:halted_step, __getobj__)
    end
  end
end

