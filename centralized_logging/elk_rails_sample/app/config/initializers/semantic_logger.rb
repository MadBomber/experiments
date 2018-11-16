# config/initializers/semantic_logger.rb

Rails.application.configure do

# Re-enable Started, Processing, and Rendered messages

config.rails_semantic_logger.started    = true
config.rails_semantic_logger.processing = true
config.rails_semantic_logger.rendered   = true

# Original Rails messages with semantic logger formatting

config.rails_semantic_logger.semantic   = false
config.rails_semantic_logger.started    = true
config.rails_semantic_logger.processing = true
config.rails_semantic_logger.rendered   = true

# Include the file name and line number in the source code where the message originated

# Warning: Either set this to nil (to disable it completely) or to a high log level (:fatal or :error) in your production environment otherwise you risk encountering a memory leak due to the very high number of objects allocated when Ruby backtraces are created. This is best used in development for debugging purposes.

config.semantic_logger.backtrace_level = :info

# Set to the log level to :trace, :debug, :info, :warn, :error, or :fatal
config.log_level = :trace

# Named Tags

# Named tags can be added to every log message on a per web request basis, by overriding the Rails built-in config.log_tags with a hash value.

# For example, add the following to application.rb, or replace the existing config.log_tags entry:

  config.log_tags = {
    request_id: :request_id,
    ip:         :remote_ip,
    user:       -> request { request.cookie_jar['login'] }
  }

# Note:
#
#    If a value returns nil, that key and value will be left out of the named tags for that request.
#    :request_id above is for Rails 5 and above. With Rails 4.2 use :uuid

# To turn off named tags in development, add the following to config/environments/development.rb
# config.log_tags        = nil

# To turn off the asset logging:

config.rails_semantic_logger.quiet_assets = true

# Colorize Logging

# If the Rails colorized logging is enabled, then the colorized formatter will be used by default. To disable colorized logging in both Rails and Semantic Logger:

config.colorize_logging = false

# To disable semantic message conversion:
# config.rails_semantic_logger.semantic = false

# To show Rack started messages in production:

config.rails_semantic_logger.started = true

# To show the Controller Processing message in production:

config.rails_semantic_logger.processing = true

# To show the Action View rendering messages in production:

config.rails_semantic_logger.rendered = true

# Additional appenders

# Example, also log to a JSON log file, for consumption by ELK, Splunk, etc.:

config.semantic_logger.add_appender(file_name: "log/#{Rails.env}.json", formatter: :json)

# Example, also log to a local Syslog:
# config.semantic_logger.add_appender(appender: syslog)

# Example, also log to a local Syslog such as syslog-ng over TCP:
# config.semantic_logger.add_appender(appender: syslog, url: 'tcp://myloghost:514')

# Example, also log to elasticsearch:
# config.semantic_logger.add_appender(appender: :elasticsearch, url: 'http://localhost:9200')

# Example, also log to BugSnag:
# config.semantic_logger.add_appender(appender: :bugsnag)

# Log messages can be written to one or more of the following destinations at the same time:
#
#     Text File
#     $stderr or $stdout ( any IO stream )
#     Syslog
#     Graylog
#     Elasticsearch
#     Splunk
#     logentries.com
#     loggly.com
#     Logstash
#     Papertrail
#     New Relic
#     Bugsnag
#     Signalfx
#     Apache Kafka
#     HTTP(S)
#     TCP (+ SSL)
#     UDP
#     MongoDB
#     Logger, log4r, etc.





end # Rails.application.configure do