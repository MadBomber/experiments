#!/usr/bin/env -S falcon-host

# falcon-rails ran into a problem on AWS ECS where it was pinning
# the cpu's at 100%  This configuration seems to have solved that
# problem.  See this issue:
# https://github.com/socketry/falcon/issues/323
#


# Falcon host config for Rails on ECS/Fargate (arm64), Falcon 0.52.4+
# - Workers: FALCON_WORKERS || ECS metadata Limits.CPU || Falcon default (Etc.nprocessors)
# - Supervisor memory limits: derived from /proc/meminfo; overridable via FALCON_SUPERVISOR_* envs
# - HTTP/1.1 backend by default (ALB target); optional HTTP/2 via FALCON_HTTP_PROTOCOL=h2|http2
# Run this in the dockerfile via `CMD ["bundle", "exec", "falcon", "host"]`

require 'etc'
require 'json'
require 'net/http'
require 'uri'
require 'fileutils'
require 'tmpdir'
require 'active_support/core_ext/object/blank'
require 'falcon/environment/rack'
require 'falcon/environment/supervisor'

$stdout.sync = true

module RailsAppFalconConfig
  module_function

  # --- helpers -----------------------------------------------------

  # @param uri_str [String]
  # @param timeout [Float]
  # @return [Hash, nil]
  def http_get_json(uri_str, timeout: metadata_timeout)
    uri = URI(uri_str)
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = timeout
    http.read_timeout = timeout
    res = http.get(uri.request_uri)
    return nil unless res.is_a?(Net::HTTPSuccess)
    JSON.parse(res.body)
  rescue StandardError
    nil
  end

  # @return [Float]
  def metadata_timeout
    value = Float(ENV.fetch('FALCON_METADATA_TIMEOUT', '0.5'))
    value.positive? ? value : 0.5
  rescue ArgumentError, TypeError
    0.5
  end

  # @return [Integer, nil]
  def ecs_vcpu_limit
    return @ecs_vcpu_limit if defined?(@ecs_vcpu_limit)

    base = ENV['ECS_CONTAINER_METADATA_URI_V4']
    unless base.present?
      @ecs_vcpu_limit = nil
      return @ecs_vcpu_limit
    end

    base = base.end_with?('/') ? base : "#{base}/"

    document = http_get_json("#{base}task") || http_get_json(base)
    cpu_value = document&.dig('Limits', 'CPU')
    @ecs_vcpu_limit = normalize_vcpu(cpu_value)
  end

  # @return [Integer, nil]
  def desired_worker_count
    env = Integer(ENV.fetch('FALCON_WORKERS', ''), exception: false)
    if env && env.positive?
      @worker_count_source = :env
      return env
    end

    metadata = ecs_vcpu_limit
    if metadata && metadata.positive?
      @worker_count_source = :metadata
      return metadata
    end

    @worker_count_source = :fallback
    fallback_worker_count
  end

  # @return [Integer]
  def fallback_worker_count
    fallback = Integer(ENV.fetch('FALCON_FALLBACK_WORKERS', ''), exception: false)
    return fallback if fallback && fallback.positive?

    1
  end

  # @return [String]
  def supervisor_ipc_path
    dir = ENV.fetch('FALCON_SUPERVISOR_SOCKET_DIR', File.join(Dir.tmpdir, 'falcon'))
    FileUtils.mkdir_p(dir)
    File.join(dir, 'supervisor.ipc')
  end

  # @return [Symbol, nil]
  def worker_count_source
    defined?(@worker_count_source) ? @worker_count_source : nil
  end

  # Total memory (bytes) from /proc/meminfo (Fargate/Linux), or nil on macOS.
  # @return [Integer, nil]
  def mem_total_bytes
    if (kb = File.read('/proc/meminfo')[/^MemTotal:\s+(\d+)\s+kB/i, 1])
      return kb.to_i * 1024
    end
    nil
  rescue StandardError
    nil
  end

  # Returns [per_worker_limit_bytes, total_limit_bytes].
  # Defaults: 75% of MemTotal for cluster; ~25% per worker, clamped to [300 MiB, 1024 MiB]
  # and further bounded so workers_sum <= total_limit.
  # @param worker_count [Integer]
  # @return [Array(Integer, Integer)]
  def derived_memory_limits(worker_count)
    # Explicit overrides (MiB):
    per_mb = Integer(ENV.fetch('FALCON_SUPERVISOR_PER_WORKER_MB', ''), exception: false)
    tot_mb = Integer(ENV.fetch('FALCON_SUPERVISOR_TOTAL_MB', ''), exception: false)
    if per_mb && per_mb.positive? && tot_mb && tot_mb.positive?
      return [per_mb * 1024 * 1024, tot_mb * 1024 * 1024]
    end

    mt = mem_total_bytes
    return [400 * 1024 * 1024, 1200 * 1024 * 1024] unless mt && mt.positive?

    target_total = (mt * 0.75).to_i

    per_worker = (mt * 0.25).to_i
    per_worker = [per_worker, 1024 * 1024 * 1024].min
    per_worker = [per_worker, (target_total / [worker_count, 1].max)].min
    per_worker = [per_worker, 300 * 1024 * 1024].max

    [per_worker, target_total]
  end

  # @return [Async::HTTP::Protocol::HTTP2, Async::HTTP::Protocol::HTTP11]
  def http_protocol
    case ENV.fetch('FALCON_HTTP_PROTOCOL', 'http1').downcase
    when 'http2', 'h2'
      Async::HTTP::Protocol::HTTP2
    else
      Async::HTTP::Protocol::HTTP11
    end
  end

  # @param cpu_value [Object]
  # @return [Integer, nil]
  def normalize_vcpu(cpu_value)
    v = cpu_value.to_f
    return nil unless v.positive?

    # ECS may supply CPU as vCPUs (0.25, 1.0, etc.) or CPU units (256, 1024, etc.).
    v /= 1024.0 if v > 10

    workers = v.ceil
    workers = 1 if workers < 1
    workers
  end
end

# --- web service ---------------------------------------------------

service 'railsapp' do
  include Falcon::Environment::Rack

  # Preload Rails (preload.rb should require "config/environment")
  preload 'preload.rb'

  port { Integer(ENV.fetch('HTTP_PORT', 8080)) }

  # Force HTTP/1.1 behind ALB unless explicitly overridden
  # Backend (ALB→target) HTTP/2 is optional and comes with tight constraints:
  # the target group must use the HTTP/2 protocol version, the listener must be
  # HTTPS, and only instance/ip targets are supported. Our Falcon host currently
  # speaks plain HTTP/1.1 on port 8080; enabling HTTP/2 from the load balancer
  # would require (a) letting Falcon run with HTTP/2 and (b) deciding whether to
  # terminate TLS at the app instead of—or in addition to—the ALB.
  # Without those changes the ALB cannot successfully establish HTTP/2 back-end
  # connections, so we intentionally default to HTTP/1.1.
  endpoint do
    Async::HTTP::Endpoint
      .parse("http://0.0.0.0:#{port}")
      .with(protocol: RailsAppFalconConfig.http_protocol)
  end

  workers = RailsAppFalconConfig.desired_worker_count
  count workers
  case RailsAppFalconConfig.worker_count_source
  when :env
    warn "[falcon] workers=#{workers} (FALCON_WORKERS override)"
  when :metadata
    warn "[falcon] workers=#{workers} (ECS metadata)"
  when :fallback
    warn "[falcon] workers=#{workers} (fallback default)"
  else
    warn "[falcon] workers=#{workers} (source unknown)"
  end

  # Mark this service to be supervised (health/restarts).
  include Async::Container::Supervisor::Supervised

  supervisor_ipc_path { RailsAppFalconConfig.supervisor_ipc_path }
end

# --- supervisor ----------------------------------------------------

service 'supervisor' do
  include Falcon::Environment::Supervisor

  ipc_path { RailsAppFalconConfig.supervisor_ipc_path }

  # Derive limits based on the same worker count resolver:
  workers = RailsAppFalconConfig.desired_worker_count
  per_worker_limit, total_limit = RailsAppFalconConfig.derived_memory_limits(workers)

  mt = RailsAppFalconConfig.mem_total_bytes
  human_mt = mt ? "#{(mt / 1024.0 / 1024.0).round} MiB" : 'unknown'
  warn "[falcon] MemTotal=#{human_mt} " \
       "supervisor: #{(per_worker_limit / 1024 / 1024)} MiB/worker, " \
       "#{(total_limit / 1024 / 1024)} MiB total, workers=#{workers}"

  monitors do
    [
      Async::Container::Supervisor::MemoryMonitor.new(
        interval: 10,
        maximum_size_limit: per_worker_limit,
        total_size_limit: total_limit,
      ),
    ]
  end
end
