module SimpleFlow
  ##
  # This class represents the result of an operation within a simple flow system.
  #
  # It encapsulates the operation's outcome (value), contextual data (context),
  # and any errors occurred during the operation (errors). Its primary purpose
  # is to facilitate flow control and error handling in a clean and predictable
  # manner. The class provides mechanisms to update context and errors, halt 
  # the flow, and conditionally continue based on the operation state. This
  # promotes creating a chainable, fluent interface for managing operation
  # results in complex processes or workflows.
  #
  class Result
    # The outcome of the operation.
    attr_reader :value

    # Contextual data related to the operation.
    attr_reader :context

    # Errors occurred during the operation.
    attr_reader :errors

    # Initializes a new Result instance.
    # @param value [Object] the outcome of the operation.
    # @param context [Hash, optional] contextual data related to the operation.
    # @param errors [Hash, optional] errors occurred during the operation.
    def initialize(value, context: {}, errors: {})
      @value = value
      @context = context
      @errors = errors
      @continue = true
    end

    # Adds or updates context to the result.
    # @param key [Symbol] the key to store the context under.
    # @param value [Object] the value to store.
    # @return [Result] a new Result instance with updated context.
    def with_context(key, value)
      self.class.new(@value, context: @context.merge(key => value), errors: @errors)
    end

    # Adds an error message under a specific key.
    # If the key already exists, it appends the message to the existing errors.
    # @param key [Symbol] the key under which the error should be stored.
    # @param message [String] the error message.
    # @return [Result] a new Result instance with updated errors.
    def with_error(key, message)
      self.class.new(@value, context: @context, errors: @errors.merge(key => [*@errors[key], message]))
    end

    # Halts the flow, optionally updating the result's value.
    # @param new_value [Object, nil] the new value to set, if any.
    # @return [Result] a new Result instance or self if no new value is provided.
    def halt(new_value = nil)
      @continue = false
      new_value ? with_value(new_value) : self
    end

    # Continues the flow, updating the result's value.
    # @param new_value [Object] the new value to set.
    # @return [Result] a new Result instance with the new value.
    def continue(new_value)
      with_value(new_value)
    end

    # Checks if the operation should continue.
    # @return [Boolean] true if the operation should continue, else false.
    def continue?
      @continue
    end

    private

    # Creates a new Result instance with updated value.
    # @param new_value [Object] the new value for the result.
    # @return [Result] a new Result instance.
    def with_value(new_value)
      self.class.new(new_value, context: @context, errors: @errors)
    end
  end
end
