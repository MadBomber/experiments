#!/usr/bin/env ruby
# example_map_reduce_queue.rb
# See: https://blog.dnsimple.com/2018/05/simple-async-map-reduce-queue-for-ruby/


# frozen_string_literal: true

require "ostruct"
require "concurrent"

class MyQueue
  # FORMERLY KNOWN AS Worker
  class SyncWorker
    def initialize(&blk)
      @blk = blk
    end

    def call
      @blk.call
    end
  end

  # NEW OBJECT
  class AsyncWorker
    def initialize(&blk)
      @blk = Concurrent::Promise.execute(&blk)
    end

    def call
      @blk.value
    end
  end

  class Result
    def initialize(merged)
      @merged = merged
    end

    def in_sync?
      @merged.all?(&:in_sync)
    end

    def errors
      @merged.map(&:error).compact
    end
  end

  # NEW METHOD
  def self.build(async: true)
    worker = async ? AsyncWorker : SyncWorker
    new(worker: worker)
  end

  def initialize(worker:)
    @worker  = worker
    @workers = []
  end

  def map(&blk)
    @workers << @worker.new(&blk)
  end

  def reduce(accumulator)
    merged = @workers.each_with_object(accumulator) do |worker, acc|
      yield worker.call, acc
    end

    Result.new(merged)
  end
end

class Processor
  def call(server)
    result = OpenStruct.new(name: server, in_sync: true)
    sleep rand(0..3)
    puts "#{Time.now.utc} - querying: #{server}"
    raise "boom #{server}" if rand(1_000) < 1
    result
  rescue => exception
    result.in_sync = false
    result.error   = exception.message
    result
  end
end

# MOAR SERVERS 🙀
servers = (1..60).map { |i| "server#{i}.test" }
queue = MyQueue.build
processor = Processor.new

servers.each do |server|
  queue.map do
    processor.call(server)
  end
end

result = queue.reduce([]) do |server, memo|
  memo << server
end

if result.in_sync?
  puts "in sync: true"
else
  puts "in sync: false - errors: #{result.errors.join(', ')}"
end
