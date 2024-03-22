require 'minitest/autorun'
require 'logger'
require_relative 'middleware'

module SimpleFlow
  module MiddleWare
    class TestLogging < Minitest::Test
      def setup
        @callable = ->(result) { "Processed: #{result}" }
        @logger = Logger.new($stdout)
        @logging_middleware = Logging.new(@callable, @logger)
      end
            
        def test_call_logs_correctly
          result = "initial"
          output = StringIO.new
          logger = Logger.new(output)
          
          # Make sure the middleware uses this logger
          @logging_middleware = Logging.new(@callable, logger)
          
          processed_result = @logging_middleware.call(result)
          
          # Check if the expected log messages are present in the output
          assert_match(/Before call/, output.string)
          assert_match(/After call/, output.string)
          assert_equal "Processed: initial", processed_result
      end

    end

    class TestInstrumentation < Minitest::Test
      def setup
        @callable = ->(result) { "Processed: #{result}" }
        @instrumentation_middleware = Instrumentation.new(@callable, api_key: "API_KEY")
      end

      def test_call_instruments_correctly
        result = "initial"
        output = StringIO.new
        $stdout = output
        
        processed_result = @instrumentation_middleware.call(result)
        
        $stdout = STDOUT
        assert_match(/Instrumentation: API_KEY took/, output.string)
        assert_equal "Processed: initial", processed_result
      end
    end
  end
end
