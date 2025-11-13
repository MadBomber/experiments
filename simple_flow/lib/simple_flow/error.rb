# frozen_string_literal: true

module SimpleFlow
  # Base error class for SimpleFlow exceptions
  class Error < StandardError; end

  # Raised when a circular dependency is detected in DAG pipelines
  class CircularDependencyError < Error; end

  # Raised when a step is not found in the pipeline
  class StepNotFoundError < Error; end

  # Raised when invalid configuration is provided
  class ConfigurationError < Error; end

  ##
  # Structured error object for tracking errors within pipeline execution
  #
  class ExecutionError
    attr_reader :step, :message, :severity, :timestamp, :exception

    # @param step [String, Symbol] the step name where error occurred
    # @param message [String] the error message
    # @param severity [Symbol] one of :warning, :error, :critical
    # @param exception [Exception, nil] the original exception if any
    def initialize(step:, message:, severity: :error, exception: nil)
      @step = step
      @message = message
      @severity = severity
      @timestamp = Time.now
      @exception = exception
    end

    # @return [Boolean] true if severity is :critical
    def critical?
      @severity == :critical
    end

    # @return [Boolean] true if severity is :error or :critical
    def error?
      %i[error critical].include?(@severity)
    end

    # @return [Boolean] true if severity is :warning
    def warning?
      @severity == :warning
    end

    # @return [String] formatted error message
    def to_s
      "[#{@severity.upcase}] #{@step}: #{@message}"
    end

    # @return [Hash] hash representation
    def to_h
      {
        step: @step,
        message: @message,
        severity: @severity,
        timestamp: @timestamp,
        exception: @exception&.class&.name
      }
    end
  end
end
