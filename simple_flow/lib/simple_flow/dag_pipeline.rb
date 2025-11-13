# frozen_string_literal: true

require 'tsort'
require_relative 'pipeline'
require_relative 'error'

module SimpleFlow
  ##
  # DAG-based pipeline with dependency resolution and parallel execution support
  #
  # Inspired by the Dagwood gem, this pipeline uses directed acyclic graphs (DAGs)
  # to determine execution order based on dependencies. It supports both serial
  # and parallel execution modes.
  #
  # @example Basic usage with dependencies
  #   pipeline = SimpleFlow::DagPipeline.new do
  #     step :fetch_user, ->(result) { result.continue(fetch_user(result.value)) }
  #
  #     step :fetch_posts, ->(result) { result.continue(fetch_posts(result.value)) },
  #       depends_on: [:fetch_user]
  #
  #     step :fetch_comments, ->(result) { result.continue(fetch_comments(result.value)) },
  #       depends_on: [:fetch_user]
  #
  #     step :combine, ->(result) { result.continue(combine(result.value)) },
  #       depends_on: [:fetch_posts, :fetch_comments]
  #   end
  #
  #   # Execute in dependency order (serial)
  #   result = pipeline.call(initial_result)
  #
  #   # Execute with parallel steps (fetch_posts and fetch_comments run in parallel)
  #   result = pipeline.call_parallel(initial_result)
  #
  class DagPipeline < Pipeline
    include TSort

    # @return [Hash<Symbol, Array<Symbol>>] dependency graph
    attr_reader :dependencies

    def initialize(name: nil, &config)
      @dependencies = {}
      super
    end

    # Adds a step with optional dependencies
    # @param name [Symbol, String] the step name
    # @param callable [Proc, #call, nil] the callable to execute
    # @param depends_on [Array<Symbol>, Symbol, nil] steps this step depends on
    # @param options [Hash] additional step options
    # @param block [Block] alternative way to provide the callable
    # @return [self] for method chaining
    def step(name, callable = nil, depends_on: nil, **options, &block)
      # Register dependencies
      @dependencies[name.to_sym] = Array(depends_on).compact.map(&:to_sym)

      # Validate dependencies exist or will exist
      validate_dependencies_later(name, @dependencies[name.to_sym])

      # Call parent to add the step
      super(name, callable, **options, &block)
    end

    # Adds a conditional step with dependencies
    def step_if(name, condition, callable = nil, depends_on: nil, **options, &block)
      @dependencies[name.to_sym] = Array(depends_on).compact.map(&:to_sym)
      validate_dependencies_later(name, @dependencies[name.to_sym])
      super(name, condition, callable, **options, &block)
    end

    # Executes the pipeline in dependency order (serial execution)
    # @param result [Result] the initial result
    # @return [Result] the final result
    def call(result)
      execution_order = sorted_steps
      execute_steps_serial(result, execution_order)
    end

    # Executes the pipeline with parallel execution where possible
    # @param result [Result] the initial result
    # @param max_threads [Integer] maximum number of parallel threads
    # @return [Result] the final result
    def call_parallel(result, max_threads: 4)
      execution_groups = parallel_groups
      execute_steps_parallel(result, execution_groups, max_threads)
    end

    # Returns steps in dependency order (topologically sorted)
    # @return [Array<Symbol>] step names in execution order
    def sorted_steps
      validate_no_cycles!
      tsort.map(&:to_sym)
    end

    # Returns steps grouped by parallel execution waves
    # @return [Array<Array<Symbol>>] groups of steps that can run in parallel
    def parallel_groups
      validate_no_cycles!

      order = sorted_steps
      groups = []
      processed = []

      until order.empty?
        # Find all steps whose dependencies are satisfied
        ready = order.select { |step|
          deps = @dependencies[step] || []
          deps.all? { |dep| processed.include?(dep) }
        }

        # If no steps are ready but we have steps left, there's a problem
        break if ready.empty?

        groups << ready.sort
        processed.concat(ready)
        order -= ready
      end

      groups
    end

    # Creates a subpipeline containing only the specified step and its dependencies
    # @param step_name [Symbol, String] the target step
    # @return [DagPipeline] a new pipeline with the subgraph
    def subgraph(step_name)
      step_sym = step_name.to_sym
      raise StepNotFoundError, "Step #{step_name} not found" unless @dependencies.key?(step_sym)

      # Recursively collect all dependencies
      required_steps = collect_dependencies(step_sym)

      # Create new pipeline with filtered steps
      new_pipeline = self.class.new(name: :"#{@name}_subgraph_#{step_name}")
      new_pipeline.middlewares = @middlewares.dup
      new_pipeline.dependencies = @dependencies.select { |k, _| required_steps.include?(k) }

      # Add steps in order and rebuild index
      new_index = {}
      required_steps.each do |name|
        index = @step_index[name]
        if index
          new_pipeline.steps << @steps[index]
          new_index[name] = new_pipeline.steps.size - 1
        end
      end

      new_pipeline.instance_variable_set(:@step_index, new_index)
      new_pipeline
    end

    # Merges another DAG pipeline into this one
    # @param other [DagPipeline] the pipeline to merge
    # @return [DagPipeline] a new merged pipeline
    def merge(other)
      raise ConfigurationError, "Can only merge with another DagPipeline" unless other.is_a?(DagPipeline)

      merged = self.class.new(name: :"#{@name}_merged")

      # Merge dependencies
      all_deps = @dependencies.dup
      other.dependencies.each do |key, deps|
        all_deps[key] = (all_deps[key] || []) | deps
      end
      merged.dependencies = all_deps

      # Merge middlewares and steps
      merged.middlewares = @middlewares + other.middlewares
      merged.steps = @steps + other.steps

      # Rebuild step index
      merged.send(:rebuild_step_index)

      merged
    end

    protected

    attr_writer :dependencies

    private

    # TSort interface - iterate over all nodes
    def tsort_each_node(&block)
      @dependencies.keys.each(&block)
    end

    # TSort interface - iterate over dependencies for a node
    def tsort_each_child(node, &block)
      (@dependencies[node] || []).each(&block)
    end

    # Validates no circular dependencies exist
    def validate_no_cycles!
      tsort
    rescue TSort::Cyclic => e
      raise CircularDependencyError, "Circular dependency detected: #{e.message}"
    end

    # Collects all dependencies recursively for a step
    def collect_dependencies(step_name, collected = Set.new)
      return collected if collected.include?(step_name)

      collected.add(step_name)
      deps = @dependencies[step_name] || []
      deps.each { |dep| collect_dependencies(dep, collected) }
      collected.to_a
    end

    # Validates dependencies (will be fully validated before execution)
    def validate_dependencies_later(step_name, deps)
      # Store for later validation - allows forward declarations
      @pending_validations ||= {}
      @pending_validations[step_name] = deps
    end

    # Execute steps in serial order
    def execute_steps_serial(result, execution_order)
      results_by_step = {}

      execution_order.each do |step_name|
        break unless result.continue?

        # Get the step
        step = find_step(step_name)
        next unless step

        # Execute with context from dependencies
        result = merge_dependency_results(result, step_name, results_by_step)
        result = step.call(result)

        # Store result for dependent steps
        results_by_step[step_name] = result
      end

      result
    end

    # Execute steps in parallel groups
    def execute_steps_parallel(result, execution_groups, max_threads)
      results_by_step = {}

      execution_groups.each do |group|
        break unless result.continue?

        if group.size == 1
          # Single step, execute directly
          step_name = group.first
          step = find_step(step_name)
          if step
            result = merge_dependency_results(result, step_name, results_by_step)
            result = step.call(result)
            results_by_step[step_name] = result
          end
        else
          # Multiple steps, execute in parallel
          threads = []
          thread_results = {}
          mutex = Mutex.new

          group.each do |step_name|
            step = find_step(step_name)
            next unless step

            threads << Thread.new do
              # Each thread gets its own result copy with merged dependencies
              thread_result = merge_dependency_results(result.dup, step_name, results_by_step)
              thread_result = step.call(thread_result)

              mutex.synchronize do
                thread_results[step_name] = thread_result
              end
            end

            # Limit concurrent threads
            if threads.size >= max_threads
              threads.shift.join
            end
          end

          # Wait for all threads to complete
          threads.each(&:join)

          # Merge results from parallel execution
          result = merge_parallel_results(result, thread_results)
          results_by_step.merge!(thread_results)
        end
      end

      result
    end

    # Merges context and values from dependency results
    def merge_dependency_results(result, step_name, results_by_step)
      deps = @dependencies[step_name] || []
      return result if deps.empty?

      # Merge context from all dependencies
      deps.each do |dep_name|
        dep_result = results_by_step[dep_name]
        next unless dep_result

        # Merge context, prefixed with dependency name
        dep_result.context.each do |key, value|
          result = result.with_context(:"#{dep_name}_#{key}", value)
        end
      end

      result
    end

    # Merges results from parallel execution
    def merge_parallel_results(base_result, thread_results)
      # Combine all contexts
      merged_context = base_result.context.dup

      thread_results.each do |step_name, step_result|
        step_result.context.each do |key, value|
          merged_context[:"#{step_name}_#{key}"] = value
        end
      end

      # Combine all errors
      merged_errors = base_result.errors.dup
      thread_results.each_value do |step_result|
        step_result.errors.each do |key, errors|
          merged_errors[key] = (merged_errors[key] || []) + errors
        end
      end

      # Use the first failed result's value, or base result value
      failed_result = thread_results.values.find { |r| !r.continue? }
      final_value = failed_result ? failed_result.value : base_result.value

      # Continue only if all results continue
      should_continue = thread_results.values.all?(&:continue?)

      Result.new(
        final_value,
        context: merged_context,
        errors: merged_errors,
        continue: should_continue
      )
    end

    # Rebuilds the step index
    def rebuild_step_index
      @step_index = {}
      @steps.each_with_index do |step, index|
        name = step.is_a?(Step) ? step.name : :"step_#{index}"
        @step_index[name] = index
      end
    end
  end
end
