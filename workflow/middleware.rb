module SimpleFlow
  module MiddleWare
    class Logging
      def initialize(callable, logger = nil)
        @callable, @logger = callable, logger
      end

      def call(result)
        logger.info("Before call")
        result = @callable.call(result)
        logger.info("After call")
        result
      end

      private

      def logger
        @logger ||= Logger.new($stdout)
      end
    end

    class Instrumentation
      def initialize(callable, api_key: nil)
        @callable, @api_key = callable, api_key
      end

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
