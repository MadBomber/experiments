#!/usr/bin/env ruby
# semantic_logger_test.rb

require 'semantic_logger'

Thread.current.name = "main"

# Set the global default log level
SemanticLogger.default_level = :trace

# Log to a file, and use the colorized formatter
SemanticLogger.add_appender(file_name: 'development.log', formatter: :color)
SemanticLogger.add_appender(file_name: "development.json", formatter: :json)

# level_index #=> 0     1     2    3    4     5
level_names = %w[ trace debug info warn error fatal ]

level_names.each_with_index do |level_name, level_index|
  SemanticLogger.add_appender(
    file_name:  "#{level_name}.log",
    filter:     Proc.new { |log| level_index == log.level_index }
  )
end


SemanticLogger.add_appender(io: STDOUT, formatter: :color,
  filter: Proc.new { |log| 4 < log.level_index } # less than :error
)

# Put :error and :fatal to STDERR
SemanticLogger.add_appender(io: STDERR, level: :error, formatter: :color)

SemanticLogger.add_appender(
  appender: :elasticsearch,
  url:      'http://frank.local:9200'
)


# Create an instance of a logger
# Add the application/class name to every log message
logger = SemanticLogger['MyClass']

a,b,c = %w[ foo bar baz ]
payload = %w[ a b c ].reduce(Hash.new) {|h, k| h.merge({k => eval(k)})}

logger.trace 'this is trace-level', payload: payload
logger.info 'this is info-level', payload: payload
logger.debug 'this is debug-level', payload: payload
logger.warn 'this is warn-level', payload: payload
logger.error 'this is error-level', payload: payload
logger.fatal 'this is fatal-level', payload: payload

# New level for logging low level trace information such as data sent or received

raw_response = "<xml><user>jbloggs</user><lastname>Bloggs</lastname><firstname>Joe</firstname></xml>"
logger.trace "Raw data received from Supplier:", raw_response

# Measure and log how long it takes to execute a block of code

logger.measure_info "Called external interface" do
  # Code to call external service ...
  sleep 0.75
end


# Add tags to every log entry within the code block. For example login, session id, source ip address, username, etc.

logger.tagged('jbloggs') do
  # All log entries in this block will include the tag 'jbloggs'
  logger.info("Hello World")
  logger.debug("More messages")
end


threads = []
threads << Thread.new do
  Thread.current.name = "one"
  logger.info 'first thread'
  puts "Whats the big deal"
end

threads << Thread.new do
  Thread.current.name = "two"
  logger.warn 'thread two'
  3.times { puts "Threads are fun!" }
end


threads.each { |thr| thr.join }


logger.fatal "This is the end of the test"
