#!/usr/bin/env ruby
# frozen_string_literal: true

# Dynamic Creature Terrarium
# A terminal-based creature ecosystem where each .rb file in robots/
# defines an autonomous creature. Zeitwerk provides autoloading and
# hot-reloading, the listen gem watches for file changes.
#
# Usage:
#   bundle exec ruby main.rb

require "bundler/setup"
require "listen"

require "ratatui_ruby"
require "set"

# Async gem: optional concurrency support
ASYNC_AVAILABLE = begin
  Kernel.require "async"
  Kernel.require "async/barrier"
  true
rescue LoadError
  false
end

require_relative "lib/logging"
require_relative "lib/state_store"
require_relative "lib/llm_config"
require_relative "lib/robot_loader"
require_relative "lib/world"
require_relative "lib/renderer"
require_relative "lib/async_runner"

ROBOTS_DIR = File.join(__dir__, "robots")
TICK_RATE_DEFAULT = 0.25 # seconds between ticks (~4 ticks/sec)
TICK_RATE_MIN     = 0.05 # fastest: ~20 ticks/sec
TICK_RATE_MAX     = 2.0  # slowest: 0.5 ticks/sec
TICK_RATE_STEP    = 0.05 # adjustment per key press

class Terrarium
  def initialize
    StateStore.setup!(width: 40, height: 20)
    LlmConfig.setup!
    @loader       = RobotLoader.new(ROBOTS_DIR)
    @world        = World.new(width: 40, height: 20)
    @runner       = AsyncRunner.new
    @renderer     = Renderer.new(@world, @runner)
    @needs_reload    = false
    @winner          = nil
    @tick_rate       = TICK_RATE_DEFAULT
    @command_buffer  = nil  # nil = normal mode, String = command mode
  end

  def run
    RatatuiRuby.run do |tui|
      load_initial_robots
      start_watcher

      if ASYNC_AVAILABLE
        run_async(tui)
      else
        run_sync(tui)
      end
    end
  ensure
    @runner.shutdown
    @listener&.stop
    StateStore.reset!
    if @winner
      puts "#{@winner[:name]} wins! Last robot standing with #{@winner[:territory]} territory cells."
    else
      puts "Terrarium shutting down."
    end
  end

  private

  def load_initial_robots
    creatures = @loader.load_all
    creatures.each { |path, creature| @world.add_robot(path, creature) }
  end

  def start_watcher
    @listener = Listen.to(ROBOTS_DIR, only: /\.rb$/) do |_modified, _added, _removed|
      @needs_reload = true
    end
    @listener.start
  end

  def sync_robots
    return unless @needs_reload
    @needs_reload = false

    fresh_creatures = @loader.reload_all
    current_paths   = @world.robot_paths

    # Remove robots whose files are gone
    (current_paths - fresh_creatures.keys).each do |path|
      @world.remove_robot(path)
    end

    # Add new robots and update existing ones with fresh creature instances
    fresh_creatures.each do |path, creature|
      if current_paths.include?(path)
        @world.update_creature(path, creature)
      else
        @world.add_robot(path, creature)
      end
    end
  end

  def run_async(tui)
    Async do
      simulation_loop_async(tui)
    end
  end

  def run_sync(tui)
    simulation_loop_sync(tui)
  end

  def simulation_loop_async(tui)
    loop do
      sync_robots
      @world.tick(@runner)

      if check_winner(tui)
        LOGGER.info("EXIT: winner declared")
        break
      end

      begin
        @renderer.render(tui, tick_rate: @tick_rate, command_buffer: @command_buffer)
      rescue => e
        LOGGER.error("RENDER CRASH: #{e.class}: #{e.message}")
        LOGGER.error(e.backtrace.first(5).join("\n"))
        break
      end

      event = tui.poll_event(timeout: 0.0) # non-blocking
      result = handle_event(event)
      if result == :quit
        LOGGER.info("EXIT: quit event")
        break
      end

      @runner.async_sleep(@tick_rate) # yields to reactor
    end
  rescue => e
    LOGGER.error("LOOP CRASH: #{e.class}: #{e.message}")
    LOGGER.error(e.backtrace.first(10).join("\n"))
  end

  def simulation_loop_sync(tui)
    loop do
      sync_robots
      @world.tick

      if check_winner(tui)
        LOGGER.info("EXIT: winner declared")
        break
      end

      begin
        @renderer.render(tui, tick_rate: @tick_rate, command_buffer: @command_buffer)
      rescue => e
        LOGGER.error("RENDER CRASH: #{e.class}: #{e.message}")
        LOGGER.error(e.backtrace.first(5).join("\n"))
        break
      end

      event = tui.poll_event(timeout: @tick_rate)
      result = handle_event(event)
      if result == :quit
        LOGGER.info("EXIT: quit event")
        break
      end
    end
  rescue => e
    LOGGER.error("LOOP CRASH: #{e.class}: #{e.message}")
    LOGGER.error(e.backtrace.first(10).join("\n"))
  end

  def check_winner(tui)
    winner = @world.winner
    return false unless winner

    @winner = winner
    StateStore.log_event("*** #{winner[:name]} wins! Last robot standing with #{winner[:territory]} territory cells ***", tick: StateStore.tick_count)
    @renderer.render(tui)

    # Pause so the user can see the result
    tui.poll_event(timeout: 3.0)
    true
  end

  def handle_event(event)
    return nil unless event.key?

    if @command_buffer
      handle_command_mode_event(event)
    else
      handle_normal_mode_event(event)
    end
  end

  def handle_command_mode_event(event)
    if event == :esc
      @command_buffer = nil
    elsif event == :enter
      dispatch_command(@command_buffer)
      @command_buffer = nil
    elsif event == :backspace
      if @command_buffer.empty?
        @command_buffer = nil
      else
        @command_buffer = @command_buffer[0..-2]
      end
    elsif event.text? && !event.ctrl?
      @command_buffer << event.to_s
    end
    nil
  end

  def handle_normal_mode_event(event)
    if event == ":"
      @command_buffer = +""
      nil
    elsif event == "q"
      :quit
    elsif event == :ctrl_c
      :quit
    elsif event == :up
      @tick_rate = [(@tick_rate - TICK_RATE_STEP).round(2), TICK_RATE_MIN].max
      nil
    elsif event == :down
      @tick_rate = [(@tick_rate + TICK_RATE_STEP).round(2), TICK_RATE_MAX].min
      nil
    end
  end

  def dispatch_command(text)
    return if text.nil? || text.strip.empty?

    # Parse "RobotName: instruction" — split on first colon
    parts = text.split(":", 2)
    if parts.size < 2 || parts[1].strip.empty?
      StateStore.log_event("! Command failed: use format 'Name: instruction'", tick: StateStore.tick_count)
      return
    end

    robot_name  = parts[0].strip
    instruction = parts[1].strip

    creature = @world.find_creature_by_name(robot_name)
    unless creature
      StateStore.log_event("! Command failed: no robot named '#{robot_name}'", tick: StateStore.tick_count)
      return
    end

    creature.receive_command(instruction, @runner)
    StateStore.log_event("~ Command sent to #{creature.name}: #{instruction}", tick: StateStore.tick_count)
  end
end

Terrarium.new.run
