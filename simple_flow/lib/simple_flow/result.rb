# frozen_string_literal: true

require_relative 'error'

module SimpleFlow
  ##
  # Immutable result object representing the outcome of a pipeline step.
  #
  # This class encapsulates the operation's outcome (value), contextual data (context),
  # and any errors occurred during the operation (errors). Its primary purpose
  # is to facilitate flow control and error handling in a clean and predictable
  # manner. The class provides mechanisms to update context and errors, halt
  # the flow, and conditionally continue based on the operation state. This
  # promotes creating a chainable, fluent interface for managing operation
  # results in complex processes or workflows.
  #
  # @example Basic usage
  #   result = SimpleFlow::Result.new(42)
  #     .with_context(:user_id, 123)
  #     .with_error(:validation, "Invalid input", severity: :warning)
  #
  class Result
    # The outcome of the operation.
    attr_reader :value

    # Contextual data related to the operation.
    attr_reader :context

    # Errors occurred during the operation (Hash of Arrays of ExecutionError objects)
    attr_reader :errors

    # Initializes a new Result instance.
    # @param value [Object] the outcome of the operation
    # @param context [Hash] contextual data related to the operation
    # @param errors [Hash<Symbol, Array<ExecutionError>>] errors occurred during the operation
    # @param continue [Boolean] whether execution should continue
    def initialize(value, context: {}, errors: {}, continue: true)
      @value = value
      @context = context.freeze
      @errors = errors.freeze
      @continue = continue
    end

    # Adds or updates context to the result.
    # @param key [Symbol] the key to store the context under
    # @param value [Object] the value to store
    # @return [Result] a new Result instance with updated context
    def with_context(key, value)
      self.class.new(
        @value,
        context: @context.merge(key => value),
        errors: @errors,
        continue: @continue
      )
    end

    # Adds multiple context values at once
    # @param hash [Hash] the context values to add
    # @return [Result] a new Result instance with updated context
    def merge_context(hash)
      self.class.new(
        @value,
        context: @context.merge(hash),
        errors: @errors,
        continue: @continue
      )
    end

    # Adds an error message under a specific key.
    # If the key already exists, it appends the error to the existing errors.
    # @param key [Symbol] the key under which the error should be stored
    # @param message [String] the error message
    # @param severity [Symbol] one of :warning, :error, :critical
    # @param exception [Exception, nil] the original exception if any
    # @return [Result] a new Result instance with updated errors
    def with_error(key, message, severity: :error, exception: nil)
      error = ExecutionError.new(
        step: context[:current_step] || :unknown,
        message: message,
        severity: severity,
        exception: exception
      )

      new_errors = @errors.dup
      new_errors[key] = [*@errors[key], error]

      self.class.new(
        @value,
        context: @context,
        errors: new_errors,
        continue: @continue
      )
    end

    # Halts the flow, optionally updating the result's value.
    # This is the FIX for the immutability bug - we create a new instance
    # instead of mutating @continue
    # @param new_value [Object, nil] the new value to set, if any
    # @return [Result] a new Result instance with continue set to false
    def halt(new_value = nil)
      self.class.new(
        new_value.nil? ? @value : new_value,
        context: @context,
        errors: @errors,
        continue: false
      )
    end

    # Continues the flow, updating the result's value.
    # @param new_value [Object] the new value to set
    # @return [Result] a new Result instance with the new value
    def continue(new_value)
      self.class.new(
        new_value,
        context: @context,
        errors: @errors,
        continue: @continue
      )
    end

    # Checks if the operation should continue.
    # @return [Boolean] true if the operation should continue, else false
    def continue?
      @continue
    end

    # Checks if there are any errors
    # @return [Boolean] true if errors exist
    def errors?
      !@errors.empty?
    end

    # Checks if there are any critical errors
    # @return [Boolean] true if any critical errors exist
    def critical_errors?
      all_errors.any?(&:critical?)
    end

    # Returns all errors as a flat array
    # @return [Array<ExecutionError>] all errors
    def all_errors
      @errors.values.flatten
    end

    # Returns only warning-level errors
    # @return [Array<ExecutionError>] warning errors
    def warnings
      all_errors.select(&:warning?)
    end

    # Checks if the result is successful (continues and has no errors)
    # @return [Boolean] true if successful
    def success?
      continue? && !errors?
    end

    # Checks if the result is a failure (halted or has critical/error-level errors)
    # @return [Boolean] true if failed
    def failure?
      !continue? || all_errors.any?(&:error?)
    end

    # Returns a hash representation of the result
    # @return [Hash] hash representation
    def to_h
      {
        value: @value,
        context: @context,
        errors: @errors.transform_values { |errs| errs.map(&:to_h) },
        continue: @continue,
        success: success?
      }
    end

    # String representation
    # @return [String] string representation
    def to_s
      status = success? ? "SUCCESS" : "FAILURE"
      "[#{status}] value=#{@value.inspect}, errors=#{@errors.keys}, continue=#{@continue}"
    end

    # Creates a duplicate of the result (needed for parallel execution)
    # Performs deep cloning of value to prevent shared mutable state
    # @return [Result] a new result with deep-copied values
    def dup
      self.class.new(
        deep_dup_value(@value),
        context: deep_dup_hash(@context),
        errors: deep_dup_hash(@errors),
        continue: @continue
      )
    end
    alias_method :clone, :dup

    private

    # Deep duplicate a value recursively
    # @param obj [Object] the object to duplicate
    # @return [Object] deep copy of the object
    def deep_dup_value(obj)
      case obj
      when Hash
        obj.transform_keys { |k| deep_dup_value(k) }
           .transform_values { |v| deep_dup_value(v) }
      when Array
        obj.map { |item| deep_dup_value(item) }
      when String
        obj.dup
      when Symbol, Numeric, TrueClass, FalseClass, NilClass
        obj # Immutable types
      else
        # For custom objects, try dup, fallback to original
        begin
          obj.dup
        rescue TypeError
          obj
        end
      end
    end

    # Deep duplicate a hash (used for context and errors)
    # @param hash [Hash] the hash to duplicate
    # @return [Hash] deep copy of the hash
    def deep_dup_hash(hash)
      hash.transform_keys { |k| k.is_a?(Symbol) ? k : deep_dup_value(k) }
          .transform_values { |v| deep_dup_value(v) }
    end
  end
end
