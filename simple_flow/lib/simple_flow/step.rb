# frozen_string_literal: true

require_relative 'error'

module SimpleFlow
  ##
  # Named step wrapper that adds identification, error handling, and tracking
  #
  # @example Basic usage
  #   step = SimpleFlow::Step.new(:validate_input, ->(result) {
  #     result.continue(result.value.strip)
  #   })
  #   result = step.call(initial_result)
  #
  class Step
    attr_reader :name, :callable, :options

    # @param name [Symbol, String] the step name for identification
    # @param callable [Proc, #call] the callable object to execute
    # @param options [Hash] additional options for the step
    # @option options [Boolean] :track_duration whether to track execution time
    # @option options [Boolean] :required whether this step is required
    def initialize(name, callable, **options)
      @name = name.to_sym
      @callable = callable
      @options = options
      validate!
    end

    # Executes the step with automatic error handling and context tracking
    # @param result [Result] the input result
    # @return [Result] the output result with updated context
    def call(result)
      # Add step context
      result = result.with_context(:current_step, @name)

      # Track execution time if requested
      start_time = Time.now if @options[:track_duration]

      # Execute the callable
      output = @callable.call(result)

      # Add duration to context if tracked
      if @options[:track_duration]
        duration = Time.now - start_time
        output = output.with_context(:"#{@name}_duration", duration)
      end

      output
    rescue StandardError => e
      # Capture exceptions and convert to halted result with error
      result
        .halt
        .with_error(
          :step_error,
          "#{@name}: #{e.message}",
          severity: :critical,
          exception: e
        )
        .with_context(:failed_step, @name)
    end

    # @return [String] string representation
    def to_s
      "Step<#{@name}>"
    end

    # @return [String] inspect representation
    def inspect
      "#<SimpleFlow::Step name=#{@name} options=#{@options}>"
    end

    private

    def validate!
      raise ConfigurationError, "Step callable must respond to #call" unless @callable.respond_to?(:call)
      raise ConfigurationError, "Step name cannot be nil" if @name.nil?
    end
  end

  ##
  # Conditional step that only executes if condition is met
  #
  class ConditionalStep < Step
    attr_reader :condition

    # @param name [Symbol, String] the step name
    # @param condition [Proc, #call] the condition to check
    # @param callable [Proc, #call] the callable to execute if condition is true
    # @param options [Hash] additional options
    def initialize(name, condition, callable, **options)
      @condition = condition
      super(name, callable, **options)
    end

    def call(result)
      result = result.with_context(:current_step, @name)

      if @condition.call(result)
        super(result)
      else
        result.with_context(:"#{@name}_skipped", true)
      end
    end

    private

    def validate!
      super
      raise ConfigurationError, "Condition must respond to #call" unless @condition.respond_to?(:call)
    end
  end
end
