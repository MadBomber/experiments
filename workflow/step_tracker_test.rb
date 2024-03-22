module SimpleFlow
  module MiddleWare

    ##
    # The Logging class is a middleware used for logging the beginning and ending of a method call.
    # It can be used to wrap any callable object (an object that responds to `#call`),
    # logging messages before and after the callable object is invoked.
    # Optionally, a custom logger can be passed during initialization; otherwise, it defaults to STDOUT.
    #
    class Logging
      
      # Initializes a new instance of Logging middleware.
      # @param callable [Object] An object that responds to `#call`, typically a lambda or Proc.
      # @param logger [Logger, nil] An optional logger object for logging messages.
      def initialize(callable, logger = nil)
        @callable, @logger = callable, logger
      end

      # Invokes the callable object, logging before and after the call.
      # @param result [Object] The initial argument to be passed to the callable.
      # @return [Object] The result of the callable object's invocation.
      def call(result)
        logger.info("Before call")
        result = @callable.call(result)
        logger.info("After call")
        result
      end

      private

      # Accesses or initializes the logger object.
      # Defaults to a new logger object outputting to STDOUT if none was provided during initialization.
      # @return [Logger] The logger object.
      def logger
        @logger ||= Logger.new($stdout)
      end
    end

    ##
    # The Instrumentation class is a middleware used for measuring the execution time of a method call.
    # It wraps any callable object, recording the time before and after its invocation to calculate the duration.
    # Optionally, an API key can be provided for identification purposes in instrumentation logs.
    #
    class Instrumentation

      # Initializes a new instance of Instrumentation middleware.
      # @param callable [Object] An object that responds to `#call`.
      # @param api_key [String, nil] An optional API key for logging purposes.
      def initialize(callable, api_key: nil)
        @callable, @api_key = callable, api_key
      end

      # Invokes the callable object, measuring and outputting the duration of its execution.
      # @param result [Object] The initial argument to be passed to the callable.
      # @return [Object] The result of the callable object's invocation.
      def call(result)
        start_time = Time.now
        result = @callable.call(result)
        duration = Time.now - start_time
        puts "Instrumentation: #{@api_key} took #{duration}s"
        result
      end
    end
  end
end