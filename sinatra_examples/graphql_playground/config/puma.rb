# config/puma.rb

puts <<~HEADER

  ====================
  == config/puma.rb ==
  ====================

HEADER

require 'pathname'

ROOT = Pathname.new(__FILE__).realpath.parent.parent

directory ROOT
daemonize false
rackup 'config.ru'

port ENV.fetch('APP_PORT') { 4567 }

# one worker per CPU core
workers 4


# Min and Max threads per worker
threads 1, 6

config_path = ROOT + 'config'
shared_path = ROOT + 'shared'
log_path    = shared_path + 'log'
pids_path   = shared_path + 'pids'

log_path.mkpath   unless log_path.exist?
pids_path.mkpath  unless pids_path.exist?

stdout_log = log_path + 'puma.stdout.log'
stderr_log = log_path + 'puma.stderr.log'

# Default to development
app_env = ENV['RAILS_ENV']  ||  ENV['APP_ENV']  ||  'development'
environment app_env

# Set up socket location
# bind "unix://#{shared_path}/sockets/puma.sock"

bind 'tcp://0.0.0.0:4567'

# Logging
stdout_redirect stdout_log, stderr_log, true

# Set master PID and state locations
pidfile     pids_path + 'puma.pid'
state_path  pids_path + 'puma.state'

activate_control_app

on_worker_boot do
  require "active_record"
  ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
  ActiveRecord::Base.establish_connection(YAML.load_file(config_path + 'database.yml')[app_env])
end


__END__

# The directory to operate out of.
#
# The default is the current directory.
#
directory '/home/git/gitlab'

# Load "path" as a rackup file.
#
# The default is "config.ru".
#
rackup 'config.ru'

# Daemonize the server into the background. Highly suggest that
# this be combined with "pidfile" and "stdout_redirect".
#
# The default is "false".
#
# daemonize
# daemonize false

# Store the pid of the server in the file at "path".
#
pidfile '/home/git/gitlab/tmp/pids/puma.pid'

# Use "path" as the file to store the server info state. This is
# used by "pumactl" to query and control the server.
#
state_path '/home/git/gitlab/tmp/pids/puma.state'

# Redirect STDOUT and STDERR to files specified. The 3rd parameter
# ("append") specifies whether the output is appended, the default is
# "false".
#
stdout_redirect '/home/git/gitlab/log/puma.stdout.log',
  '/home/git/gitlab/log/puma.stderr.log',
  true

# Disable request logging.
#
# The default is "false".
#
# quiet

# Configure "min" to be the minimum number of threads to use to answer
# requests and "max" the maximum.
#
# The default is "0, 16".
#
threads 1, 1

# By default, workers accept all requests and queue them to pass to handlers.
# When false, workers accept the number of simultaneous requests configured.
#
# Queueing requests generally improves performance, but can cause deadlocks if
# the app is waiting on a request to itself. See https://github.com/puma/puma/issues/612
#
# When set to false this may require a reverse proxy to handle slow clients and
# queue requests before they reach puma. This is due to disabling HTTP keepalive
queue_requests false

# Bind the server to "url". "tcp://", "unix://" and "ssl://" are the only
# accepted protocols.
#
# The default is "tcp://0.0.0.0:9292".
#
# bind 'tcp://0.0.0.0:9292'
# bind 'unix:///var/run/puma.sock'
# bind 'unix:///var/run/puma.sock?umask=0111'
# bind 'ssl://127.0.0.1:9292?key=path_to_key&cert=path_to_cert'
bind 'unix:///home/git/gitlab/tmp/sockets/gitlab.socket'
bind 'tcp://127.0.0.1:8080'

# Instead of "bind 'ssl://127.0.0.1:9292?key=path_to_key&cert=path_to_cert'" you
# can also use the "ssl_bind" option.
#
# ssl_bind '127.0.0.1', '9292', { key: path_to_key, cert: path_to_cert }

# Code to run before doing a restart. This code should
# close log files, database connections, etc.
#
# This can be called multiple times to add code each time.
#
# on_restart do
#   puts 'On restart...'
# end

on_restart do
  ActiveRecord::Base.connection.disconnect! if defined?(ActiveRecord::Base)
end

# Command to use to restart puma. This should be just how to
# load puma itself (ie. 'ruby -Ilib bin/puma'), not the arguments
# to puma, as those are the same as the original process.
#
# restart_command '/u/app/lolcat/bin/restart_puma'

# === Cluster mode ===

# How many worker processes to run.
#
# The default is "0".
#
workers 3

# Code to run when a worker boots to setup the process before booting
# the app.
#
# This can be called multiple times to add hooks.
#
# on_worker_boot do
#   puts 'On worker boot...'
# end

before_fork do
  if Rails.env.production? or Rails.env.staging?
    require 'puma_worker_killer'

    PumaWorkerKiller.config do |config|
      # For now we use the same environment variable as Unicorn, making it
      # easier to replace Unicorn with Puma.
      config.ram = (ENV['GITLAB_UNICORN_MEMORY_MAX'] || 650 * 1 << 20).to_i

      config.frequency = 5

      # We just wan't to limit to a fixed maximum, unrelated to the total amount
      # of available RAM.
      config.percent_usage = 100.0

      # Ideally we'll never hit the maximum amount of memory. If so the worker
      # is restarted already, thus periodically restarting workers shouldn't be
      # needed.
      config.rolling_restart_frequency = false
    end

    PumaWorkerKiller.start
  end
end

on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord::Base)

  defined?(::Prometheus::Client.reinitialize_on_pid_change) &&
    Prometheus::Client.reinitialize_on_pid_change
end

# Code to run when a worker boots to setup the process after booting
# the app.
#
# This can be called multiple times to add hooks.
#
# after_worker_boot do
#   puts 'After worker boot...'
# end

# Code to run when a worker shutdown.
#
#
# on_worker_shutdown do
#   puts 'On worker shutdown...'
# end

# Allow workers to reload bundler context when master process is issued
# a USR1 signal. This allows proper reloading of gems while the master
# is preserved across a phased-restart. (incompatible with preload_app)
# (off by default)

# prune_bundler

# Preload the application before starting the workers; this conflicts with
# phased restart feature. (off by default)

preload_app!

# Additional text to display in process listing
#
tag 'GitLab Puma'

#
# If you do not specify a tag, Puma will infer it. If you do not want Puma
# to add a tag, use an empty string.

# Verifies that all workers have checked in to the master process within
# the given timeout. If not the worker process will be restarted. Default
# value is 60 seconds.
#
worker_timeout 60

# Change the default worker timeout for booting
#
# If unspecified, this defaults to the value of worker_timeout.
#
# worker_boot_timeout 60

# === Puma control rack application ===

# Start the puma control rack application on "url". This application can
# be communicated with to control the main server. Additionally, you can
# provide an authentication token, so all requests to the control server
# will need to include that token as a query parameter. This allows for
# simple authentication.
#
# Check out https://github.com/puma/puma/blob/master/lib/puma/app/status.rb
# to see what the app has available.
#
# activate_control_app 'unix:///var/run/pumactl.sock'
# activate_control_app 'unix:///var/run/pumactl.sock', { auth_token: '12345' }
# activate_control_app 'unix:///var/run/pumactl.sock', { no_token: true }
#


