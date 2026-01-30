# frozen_string_literal: true

# Base class for all terrarium creatures. Each robot file in robots/
# defines a subclass (e.g., `class Wanderer < Creature`) that overrides
# the behavior methods below.
#
# Interface:
#   name        → String
#   icon        → single character
#   color       → ANSI symbol (:red, :green, :yellow, :blue, :magenta, :cyan, :white)
#   max_energy  → Integer
#   tick(state, neighbors, world)       → action hash or array of action hashes
#   encounter(other_name, other_icon)   → action hash or nil
class Creature
  def name        = "Unknown"
  attr_writer :assigned_icon

  def icon
    @assigned_icon || "Z"
  end
  def color       = :white
  def max_energy  = 100

  # Called each tick.
  # state:     { x:, y:, energy:, age: }
  # neighbors: [{ name:, icon:, distance:, direction: }]
  # world:     { width:, height:, tick:, markers: [...], territory: {...}, broadcasts: {...} }
  #
  # Returns an action hash or array of action hashes:
  #   { move: [dx, dy] }
  #   { say: "message" }
  #   { place_marker: :symbol }
  #   { absorb: true }
  def tick(state, neighbors, world)
    {}
  end

  # Called when another robot lands on an adjacent cell.
  # Returns an action hash or nil.
  def encounter(other_name, other_icon)
    nil
  end

  # --- Territory helpers ---

  # Direction [dx, dy] toward the nearest unclaimed cell, or nil if all nearby claimed.
  def territory_explore_direction(state, world)
    nearby = world.dig(:territory, :nearby)
    return nil unless nearby

    unclaimed = nearby.select { |c| c[:unclaimed] }
    return nil if unclaimed.empty?

    target = unclaimed.min_by { |c| (c[:x] - state[:x]).abs + (c[:y] - state[:y]).abs }
    dx = (target[:x] - state[:x]).clamp(-1, 1)
    dy = (target[:y] - state[:y]).clamp(-1, 1)
    [dx, dy]
  end

  # Direction [dx, dy] toward the nearest enemy-owned cell, or nil.
  def territory_reclaim_direction(state, world)
    nearby = world.dig(:territory, :nearby)
    return nil unless nearby

    enemy = nearby.reject { |c| c[:unclaimed] || c[:mine] }
    return nil if enemy.empty?

    target = enemy.min_by { |c| (c[:x] - state[:x]).abs + (c[:y] - state[:y]).abs }
    dx = (target[:x] - state[:x]).clamp(-1, 1)
    dy = (target[:y] - state[:y]).clamp(-1, 1)
    [dx, dy]
  end

  # Direction [dx, dy] toward own cell bordering enemy territory, or nil.
  def territory_patrol_direction(state, world)
    nearby = world.dig(:territory, :nearby)
    return nil unless nearby

    mine = nearby.select { |c| c[:mine] }
    enemy_positions = {}
    nearby.each { |c| enemy_positions[[c[:x], c[:y]]] = true unless c[:unclaimed] || c[:mine] }

    border = mine.select do |c|
      [[-1,0],[1,0],[0,-1],[0,1]].any? { |dx, dy| enemy_positions[[c[:x]+dx, c[:y]+dy]] }
    end
    return nil if border.empty?

    target = border.min_by { |c| (c[:x] - state[:x]).abs + (c[:y] - state[:y]).abs }
    dx = (target[:x] - state[:x]).clamp(-1, 1)
    dy = (target[:y] - state[:y]).clamp(-1, 1)
    [dx, dy]
  end

  # Blended explore/protect direction. Always returns [dx, dy].
  def territory_suggest_move(state, world, protect_weight: 0.3)
    total = world.dig(:territory, :total_cells) || 800
    my_count = world.dig(:territory, :my_count) || 0
    coverage = my_count.to_f / total

    # Increase protection bias as coverage grows
    effective_protect = protect_weight + coverage * 0.5

    if rand < effective_protect
      dir = territory_patrol_direction(state, world) || territory_reclaim_direction(state, world)
      return dir if dir
    end

    dir = territory_explore_direction(state, world)
    return dir if dir

    # Fallback: random cardinal direction
    [[-1,0],[1,0],[0,-1],[0,1]].sample
  end

  # Territory stats hash for display/LLM prompts.
  def territory_stats(world)
    {
      my_count:    world.dig(:territory, :my_count) || 0,
      total_cells: world.dig(:territory, :total_cells) || 800,
      coverage:    ((world.dig(:territory, :my_count) || 0).to_f / (world.dig(:territory, :total_cells) || 800) * 100).round(1),
      summary:     world.dig(:territory, :summary) || {}
    }
  end

  # Formats territory stats for LLM prompts.
  def territory_summary_prompt(world)
    stats = territory_stats(world)
    lines = ["Territory: #{stats[:my_count]}/#{stats[:total_cells]} cells (#{stats[:coverage]}%)"]
    stats[:summary].each { |n, c| lines << "  #{n}: #{c}" }
    lines.join("\n")
  end

  # --- Shared state helpers (via Mudis) ---

  # Store a value in this robot's private memory namespace.
  def store_memory(key, value, expires_in: nil)
    return unless defined?(StateStore)
    StateStore.store_memory(name, key, value, expires_in: expires_in)
  end

  # Recall a value from this robot's private memory.
  def recall_memory(key)
    return nil unless defined?(StateStore)
    StateStore.recall_memory(name, key)
  end

  # List keys in this robot's memory.
  def memory_keys
    return [] unless defined?(StateStore)
    StateStore.memory_keys(name)
  end

  # Broadcast a message visible to all robots (auto-expires after 30s).
  def broadcast(message)
    return unless defined?(StateStore)
    StateStore.broadcast(name, message)
  end

  # Read all current broadcasts from other robots.
  def read_broadcasts
    return {} unless defined?(StateStore)
    StateStore.all_broadcasts
  end

  # --- User command support ---

  # Receive an instruction from the user command bar.
  # Fires an LLM task to generate a dynamic method, then marks it ready.
  def receive_command(instruction, runner = nil)
    @_active_command = instruction
    @_command_method_ready = false

    unless llm_available?
      LOGGER.info("#{name}: LLM unavailable, command ignored: #{instruction}")
      @_active_command = nil
      return
    end

    prompt = build_command_prompt(instruction)

    task_body = proc do
      text = LlmConfig.ask(prompt)
      code = parse_command_response(text)
      if code
        define_singleton_method(:execute_command) do |_state, _world|
          eval(code) # rubocop:disable Security/Eval
        rescue => e
          LOGGER.error("#{name} execute_command error: #{e.message}")
          []
        end
        @_command_method_ready = true
        LOGGER.info("#{name}: command method installed for '#{instruction}'")
        save_modified_source("execute_command(_state, _world)", code, comment: "Command: #{instruction}")
      else
        LOGGER.warn("#{name}: LLM returned no usable code for '#{instruction}'")
        @_active_command = nil
      end
    end

    if runner
      runner.submit(:"#{object_id}_command", &task_body)
    else
      task_body.call
    end
  end

  def has_pending_command?
    @_active_command && @_command_method_ready
  end

  def run_pending_command(state, world)
    return [] unless has_pending_command?

    instruction = @_active_command
    @_active_command = nil
    @_command_method_ready = false

    actions = execute_command(state, world)
    Array(actions).compact
  rescue => e
    LOGGER.error("#{name} run_pending_command error: #{e.message}")
    []
  end

  # Default stub — overwritten dynamically by receive_command
  def execute_command(_state, _world)
    []
  end

  # --- LLM helpers (opt-in, no-op when unavailable) ---

  def llm_available?
    defined?(LlmConfig) && LlmConfig.available?
  end

  # Free-form LLM question. Returns response string or nil.
  # Throttled by cooldown ticks via @_llm_decide_at.
  # When @_async_runner is set, uses fire-and-forget background fibers.
  def llm_decide(prompt, cooldown: 10)
    return nil unless llm_available?

    @_llm_decide_at ||= 0
    @_llm_tick      ||= 0
    @_llm_tick      += 1
    return nil if @_llm_tick < @_llm_decide_at

    # Async path: fire-and-forget via runner
    if defined?(@_async_runner) && @_async_runner
      task_key = :"#{object_id}_llm_decide"

      # Check for completed result first
      result = @_async_runner.collect(task_key)
      if result
        @_llm_decide_at = @_llm_tick + cooldown
        return result
      end

      # Already running — don't resubmit
      return nil if @_async_runner.pending?(task_key)

      # Submit new background task
      captured_prompt = prompt
      @_async_runner.submit(task_key) do
        LlmConfig.ask(captured_prompt)
      end
      return nil
    end

    # Synchronous path
    @_llm_decide_at = @_llm_tick + cooldown
    LlmConfig.ask(prompt)
  rescue => _e
    nil
  end

  # Builds a context prompt from tick data, asks LLM for actions.
  # Returns an array of action hashes, or [] on failure.
  # When @_async_runner is set, uses fire-and-forget background fibers.
  def llm_strategize(state, neighbors, world, cooldown: 20)
    return [] unless llm_available?

    @_llm_strat_at ||= 0
    @_llm_strat_tick ||= 0
    @_llm_strat_tick += 1
    return [] if @_llm_strat_tick < @_llm_strat_at

    prompt = build_strategize_prompt(state, neighbors, world)

    # Async path: fire-and-forget via runner
    if defined?(@_async_runner) && @_async_runner
      task_key = :"#{object_id}_llm_strategize"

      result = @_async_runner.collect(task_key)
      if result
        @_llm_strat_at = @_llm_strat_tick + cooldown
        return result
      end

      return [] if @_async_runner.pending?(task_key)

      captured_prompt = prompt
      @_async_runner.submit(task_key) do
        text = LlmConfig.ask(captured_prompt)
        parse_strategize_response(text)
      end
      return []
    end

    # Synchronous path
    @_llm_strat_at = @_llm_strat_tick + cooldown

    text = LlmConfig.ask(prompt)
    parse_strategize_response(text)
  rescue => _e
    []
  end

  private

  def build_command_prompt(instruction)
    <<~PROMPT
      You are #{name}, a creature in a 2D grid world.
      Your owner just commanded: "#{instruction}"

      Generate a Ruby expression that returns an array of action hashes to carry out this command.
      Valid actions: { move: [dx, dy] }, { say: "message" }, { place_marker: :symbol }, { absorb: true }
      Where dx, dy are -1, 0, or 1.

      Return ONLY the Ruby array literal. No explanation, no markdown.
      Example: [{ move: [1, 0] }, { say: "Dancing!" }]
    PROMPT
  end

  def parse_command_response(response)
    text = response.to_s.strip
    match = text.match(/\[.*\]/m)
    return nil unless match

    match[0]
  end

  def build_strategize_prompt(state, neighbors, world)
    territory_ctx = territory_summary_prompt(world)

    <<~PROMPT
      You are #{name}, a creature in a 2D grid world.
      Your state: position=(#{state[:x]},#{state[:y]}), energy=#{state[:energy]}, age=#{state[:age]}
      World: #{world[:width]}x#{world[:height]}, tick=#{world[:tick]}
      Neighbors: #{neighbors.map { |n| "#{n[:name]} at distance #{n[:distance]} #{n[:direction]}" }.join(", ") }
      Markers nearby: #{world[:markers].size}
      #{territory_ctx}

      Return ONLY a Ruby array of action hashes. Valid actions:
        { move: [dx, dy] }   where dx,dy are -1, 0, or 1
        { say: "message" }
        { place_marker: :symbol }
        { absorb: true }

      Example: [{ move: [1, 0] }, { say: "Hello!" }]
      Think step by step, then respond with ONLY the Ruby array. /no_think
    PROMPT
  end

  def parse_strategize_response(response)
    text = response.to_s.strip
    match = text.match(/\[.*\]/m)
    return [] unless match

    eval(match[0]) # rubocop:disable Security/Eval
  rescue => _e
    []
  end

  # Detect methods generated at runtime by chaos_to_the_rescue.
  # When an undefined method is called, super delegates to chaos which
  # generates and defines the method via LLM. If a new method appears
  # after the call, we save the robot's modified source.
  def method_missing(method_name, *args, **kwargs, &block)
    had_method = respond_to?(method_name, true)
    result = super
    unless had_method
      if respond_to?(method_name, true)
        params = args.each_with_index.map { |_, i| "arg#{i}" }
        sig = params.empty? ? method_name.to_s : "#{method_name}(#{params.join(', ')})"
        save_modified_source(sig, "# Source generated at runtime by chaos_to_the_rescue", comment: "chaos_to_the_rescue")
      end
    end
    result
  end

  MODIFICATIONS_DIR = File.expand_path("../robot_modifications", __dir__)

  # Persist the robot's source file with a new method definition appended.
  # Reads the latest version from robot_modifications/ (cumulative) or
  # falls back to the original in robots/.
  def save_modified_source(method_signature, method_body, comment: nil)
    src = robot_source_path
    return unless src

    Dir.mkdir(MODIFICATIONS_DIR) unless Dir.exist?(MODIFICATIONS_DIR)

    filename = File.basename(src)
    mod_path = File.join(MODIFICATIONS_DIR, filename)

    base = File.exist?(mod_path) ? mod_path : src
    source = File.read(base)

    lines = [""]
    lines << "  # #{comment}" if comment
    lines << "  # Generated at tick #{StateStore.tick_count rescue '?'}"
    lines << "  def #{method_signature}"
    method_body.each_line { |l| lines << "    #{l.rstrip}" }
    lines << "  end"

    source.sub!(/^end\s*\z/m, "#{lines.join("\n")}\nend\n")

    File.write(mod_path, source)
    LOGGER.info("#{name}: saved modified source → #{mod_path}")
  rescue => e
    LOGGER.error("#{name}: save_modified_source failed: #{e.message}")
  end

  def robot_source_path
    filename = self.class.name
                   .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                   .downcase + ".rb"
    path = File.expand_path("../robots/#{filename}", __dir__)
    File.exist?(path) ? path : nil
  end
end
