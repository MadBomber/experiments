module SimpleFlow
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
    # @param errors [Array, optional] errors occurred during the operation as an array of hashes.
    def initialize(value, context: {}, errors: [])
      @value    = value
      @context  = context
      @errors   = errors
      @continue = true
    end


    # Adds or updates context to the result.
    # @param key [Symbol] the key to store the context under.
    # @param value [Object] the value to store.
    # @return [Result] a new Result instance with updated context.
    def with_context(key, value)
      self.class.new(@value, context: @context.merge(key => value), errors: @errors)
    end


    # Adds an error entry.
    # Each error is a Hash object, might include keys like :error_code, :error_message.
    # @param error [Hash] the error entry.
    # @return [Result] a new Result instance with updated errors array.
    def add_error(error)
      self.class.new(@value, context: @context, errors: @errors + [error])
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

    #################################################
    private

    # Creates a new Result instance with updated value.
    # @param new_value [Object] the new value for the result.
    # @return [Result] a new Result instance.
    def with_value(new_value)
      self.class.new(new_value, context: @context, errors: @errors)
    end
  end
end
