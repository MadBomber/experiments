# frozen_string_literal: true

# 2D grid simulation: robots occupy cells, move, interact, leave markers.
# All persistent state flows through StateStore (Mudis). Creature Ruby
# objects live in @creatures (not serializable). Working copies are loaded
# at the start of each tick and written back at the end.
class World
  RobotState = Struct.new(:path, :creature, :x, :y, :energy, :age, keyword_init: true)
  Marker     = Struct.new(:x, :y, :symbol, :color, :placed_at, keyword_init: true)

  TerritoryCell = Struct.new(:owner_name, :owner_color, :claimed_at, :strength, keyword_init: true)

  ICON_POOL  = [*("A".."Z"), *("a".."z")].freeze
  MAX_ROBOTS = ICON_POOL.size

  attr_reader :width, :height

  def initialize(width: 40, height: 20)
    @width     = width
    @height    = height
    @creatures  = {} # path => creature instance (Ruby objects, not in Mudis)
    @used_icons = {} # path => assigned icon character

    # Working copies — populated at start of each tick
    @_robot_data     = {}
    @_territory      = {}
    @_markers        = []
    @_absorb_intents = {}
  end

  # --- Public accessors (Renderer uses these) ---

  def tick_count
    StateStore.tick_count
  end

  def robot_states
    @_robot_data.each_with_object({}) do |(path, data), hash|
      state = build_robot_state(path, data)
      hash[path] = state if state
    end
  end

  def markers
    @_markers.map do |m|
      Marker.new(x: m[:x], y: m[:y], symbol: m[:symbol], color: m[:color], placed_at: m[:placed_at])
    end
  end

  def event_log
    StateStore.event_log
  end

  def territory
    @_territory.transform_values do |cell|
      TerritoryCell.new(owner_name: cell[:owner_name], owner_color: cell[:owner_color],
                        claimed_at: cell[:claimed_at], strength: cell[:strength] || 0)
    end
  end

  def add_robot(path, creature)
    return if @creatures.key?(path)

    icon = assign_icon(path)
    unless icon
      log_event("! #{creature.name} rejected — world full (#{MAX_ROBOTS} robots)")
      return
    end

    creature.assigned_icon = icon
    @creatures[path] = creature

    x = rand(width)
    y = rand(height)

    # Avoid spawning on top of another robot
    occupied = occupied_cells
    attempts = 0
    while occupied.include?([x, y]) && attempts < 50
      x = rand(width)
      y = rand(height)
      attempts += 1
    end

    data = {
      x: x, y: y,
      energy:     creature.max_energy,
      age:        0,
      name:       creature.name,
      icon:       icon,
      color:      creature.color,
      max_energy: creature.max_energy
    }
    StateStore.write_robot(path, data)
    @_robot_data[path] = data

    claim_territory_for(data)
    log_event("+ #{creature.name} (#{icon}) joined the world at (#{x},#{y})")
  end

  def remove_robot(path)
    data = @_robot_data.delete(path)
    creature = @creatures.delete(path)
    release_icon(path)
    StateStore.delete_robot(path)
    log_event("- #{creature&.name || data&.dig(:name) || 'unknown'} left the world") if data || creature
  end

  def update_creature(path, creature)
    old_creature = @creatures[path]
    return unless old_creature

    old_name = old_creature.name
    creature.assigned_icon = old_creature.icon
    @creatures[path] = creature

    # Update stored data with new creature attributes (icon is world-assigned, not overwritten)
    if @_robot_data[path]
      @_robot_data[path][:name]       = creature.name
      @_robot_data[path][:color]      = creature.color
      @_robot_data[path][:max_energy] = creature.max_energy
      StateStore.write_robot(path, @_robot_data[path])
    end

    log_event("~ #{old_name} reloaded as #{creature.name}")
  end

  def tick(runner = nil)
    current_tick = StateStore.increment_tick

    # Load working copies from StateStore
    @_robot_data = StateStore.all_robot_data
    @_territory  = StateStore.territory
    @_markers    = StateStore.markers

    # Snapshot positions before moves
    prev_positions = @_robot_data.transform_values { |d| [d[:x], d[:y]] }

    # Collect actions from each robot — concurrently when runner available
    actions = {}
    entries = @_robot_data.to_a

    if runner
      entries.each { |_path, data| data[:age] += 1 }
      results = runner.map_concurrent(entries) { |(_path, data)| safe_tick_data(data, current_tick, runner) }
      entries.each_with_index { |(path, _data), idx| actions[path] = results[idx] }
    else
      entries.each do |path, data|
        data[:age] += 1
        actions[path] = safe_tick_data(data, current_tick)
      end
    end

    # Resolve actions (sequential — mutates working copies, collects absorb intents)
    @_absorb_intents = {}
    actions.each do |path, action_list|
      resolve_actions(path, action_list)
    end

    # Update fortification strength and siege progress
    update_fortifications(prev_positions)

    # Trigger encounters for adjacent robots (may add more absorb intents)
    check_encounters

    # Resolve all collected absorb intents as energy-drain battles
    resolve_battles

    # Remove robots that ran out of energy
    cull_dead_robots

    # Write working copies back to StateStore
    StateStore.write_all_robots(@_robot_data)
    StateStore.territory = @_territory
    StateStore.markers   = @_markers
  end

  def robot_count
    @_robot_data.size
  end

  # Returns the sole surviving robot's data hash if exactly one remains, nil otherwise.
  def winner
    return nil unless @_robot_data.size == 1

    path, data = @_robot_data.first
    creature = @creatures[path]
    return nil unless creature

    { name: data[:name], icon: data[:icon], color: data[:color], territory: territory_summary[data[:name]] || 0 }
  end

  def robot_paths
    @creatures.keys
  end

  # Find a creature instance by name (case-insensitive). Returns the creature or nil.
  def find_creature_by_name(name)
    @creatures.values.find { |c| c.name.downcase == name.downcase }
  end

  def cell_at(x, y)
    path, data = @_robot_data.find { |_, d| d[:x] == x && d[:y] == y }
    return nil unless path

    build_robot_state(path, data)
  end

  def marker_at(x, y)
    m = @_markers.find { |m| m[:x] == x && m[:y] == y }
    return nil unless m

    Marker.new(x: m[:x], y: m[:y], symbol: m[:symbol], color: m[:color], placed_at: m[:placed_at])
  end

  def territory_at(x, y)
    cell = @_territory[[x, y]]
    return nil unless cell

    TerritoryCell.new(owner_name: cell[:owner_name], owner_color: cell[:owner_color],
                      claimed_at: cell[:claimed_at], strength: cell[:strength] || 0)
  end

  def resize(new_width, new_height)
    return if new_width == @width && new_height == @height
    return if new_width < 1 || new_height < 1

    @width  = new_width
    @height = new_height
    StateStore.dimensions = { width: new_width, height: new_height }

    # Clamp all robots into the new bounds
    @_robot_data.each_value do |data|
      data[:x] = data[:x].clamp(0, @width - 1)
      data[:y] = data[:y].clamp(0, @height - 1)
    end

    # Clamp markers and discard out-of-bounds ones
    @_markers.select! { |m| m[:x] < @width && m[:y] < @height }

    # Discard territory cells outside new bounds
    @_territory.delete_if { |key, _| key[0] >= @width || key[1] >= @height }

    # Write clamped data back
    StateStore.write_all_robots(@_robot_data)
    StateStore.markers   = @_markers
    StateStore.territory = @_territory
  end

  def territory_summary
    counts = Hash.new(0)
    @_territory.each_value { |cell| counts[cell[:owner_name]] += 1 }
    counts
  end

  private

  def build_robot_state(path, data)
    creature = @creatures[path]
    return nil unless creature

    RobotState.new(path: path, creature: creature, x: data[:x], y: data[:y], energy: data[:energy], age: data[:age])
  end

  def occupied_cells
    @_robot_data.values.map { |d| [d[:x], d[:y]] }.to_set
  end

  def claim_territory_for(data)
    key = [data[:x], data[:y]]
    existing = @_territory[key]

    if existing.nil?
      @_territory[key] = new_territory_cell(data)
    elsif existing[:owner_name] == data[:name]
      # Already ours — strength updated in update_fortifications
    elsif (existing[:strength] || 0) == 0
      @_territory[key] = new_territory_cell(data)
    end
    # Fortified rival territory: skip — handled by update_fortifications
  end

  def new_territory_cell(data)
    { owner_name: data[:name], owner_color: data[:color],
      claimed_at: StateStore.tick_count, strength: 0,
      siege_by: nil, siege_progress: 0 }
  end

  def find_nearby_territory(data, radius: 5)
    cx, cy = data[:x], data[:y]
    nearby = []
    (-radius..radius).each do |dy|
      (-radius..radius).each do |dx|
        tx = cx + dx
        ty = cy + dy
        next if tx < 0 || tx >= @width || ty < 0 || ty >= @height

        cell = @_territory[[tx, ty]]
        nearby << {
          x: tx, y: ty,
          owner_name:  cell&.dig(:owner_name),
          owner_color: cell&.dig(:owner_color),
          strength:    cell&.dig(:strength) || 0,
          mine:        cell&.dig(:owner_name) == data[:name],
          unclaimed:   cell.nil?
        }
      end
    end
    nearby
  end

  def safe_tick_data(data, current_tick, runner = nil)
    creature = @creatures.values.find { |c| c.name == data[:name] }
    return [] unless creature

    neighbors = find_neighbors_for(data)
    summary = territory_summary
    my_count = summary[data[:name]] || 0

    # Inject async runner so LLM helpers can fire-and-forget
    creature.instance_variable_set(:@_async_runner, runner) if runner

    world_info = {
      width:   @width,
      height:  @height,
      tick:    current_tick,
      markers: @_markers.map { |m| { x: m[:x], y: m[:y], symbol: m[:symbol] } },
      territory: {
        nearby:      find_nearby_territory(data),
        my_count:    my_count,
        total_cells: @width * @height,
        summary:     summary
      },
      broadcasts: StateStore.all_broadcasts
    }
    state_info = {
      x:      data[:x],
      y:      data[:y],
      energy: data[:energy],
      age:    data[:age]
    }

    result = creature.tick(state_info, neighbors, world_info)
    actions = Array(result).compact

    # Execute pending user command if the LLM method is ready
    if creature.has_pending_command?
      command_actions = creature.run_pending_command(state_info, world_info)
      actions.concat(Array(command_actions).compact)
    end

    actions
  rescue => e
    LOGGER.error("Tick error for #{data[:name]}: #{e.message}")
    []
  end

  def find_neighbors_for(data)
    @_robot_data.values.filter_map do |other|
      next if other[:name] == data[:name] && other[:x] == data[:x] && other[:y] == data[:y]

      dx = other[:x] - data[:x]
      dy = other[:y] - data[:y]
      dist = Math.sqrt(dx**2 + dy**2)
      next if dist > 5 # visibility range

      direction = if dx.abs > dy.abs
                    dx > 0 ? :east : :west
                  else
                    dy > 0 ? :south : :north
                  end

      {
        name:      other[:name],
        icon:      other[:icon],
        distance:  dist.round(1),
        direction: direction
      }
    end
  end

  def resolve_actions(path, action_list)
    data = @_robot_data[path]
    return unless data

    action_list.each do |action|
      next unless action.is_a?(Hash)

      resolve_move(path, data, action[:move])           if action[:move]
      resolve_say(data, action[:say])                   if action[:say]
      resolve_marker(data, action[:place_marker])       if action[:place_marker]
      @_absorb_intents[path] = true                     if action[:absorb]
    end
  end

  def resolve_move(path, data, delta)
    dx, dy = delta
    new_x = (data[:x] + dx.to_i).clamp(0, @width - 1)
    new_y = (data[:y] + dy.to_i).clamp(0, @height - 1)

    # Only move if cell is unoccupied
    unless @_robot_data.any? { |p, d| p != path && d[:x] == new_x && d[:y] == new_y }
      data[:x] = new_x
      data[:y] = new_y
    end

    # Gain energy when occupying another robot's territory
    cell = @_territory[[data[:x], data[:y]]]
    if cell && cell[:owner_name] != data[:name]
      data[:energy] += 1
    end

    claim_territory_for(data)
    data[:energy] -= 1
  end

  def resolve_say(data, message)
    log_event("[#{data[:name]}] #{message}")
  end

  def resolve_marker(data, symbol)
    # Remove any existing marker at this position
    @_markers.reject! { |m| m[:x] == data[:x] && m[:y] == data[:y] }

    @_markers << {
      x:         data[:x],
      y:         data[:y],
      symbol:    symbol.to_s[0] || ".",
      color:     data[:color],
      placed_at: StateStore.tick_count
    }

    # Cap total markers
    @_markers.shift if @_markers.size > 200
  end

  def resolve_battles
    return if @_absorb_intents.empty?

    # Map each attacker to its nearest adjacent target
    attacks = {}
    @_absorb_intents.each_key do |attacker_path|
      attacker_data = @_robot_data[attacker_path]
      next unless attacker_data

      target_path, target_data = @_robot_data
        .reject { |p, _| p == attacker_path }
        .select { |_, d| (d[:x] - attacker_data[:x]).abs <= 1 && (d[:y] - attacker_data[:y]).abs <= 1 }
        .min_by { |_, d| (d[:x] - attacker_data[:x]).abs + (d[:y] - attacker_data[:y]).abs }

      next unless target_data
      attacks[attacker_path] = { target_path: target_path, attacker_data: attacker_data, target_data: target_data }
    end

    # Log group battles (2+ attackers on same target)
    attacks.values.group_by { |a| a[:target_path] }.each do |_target_path, attackers|
      next unless attackers.size > 1
      target_name = attackers.first[:target_data][:name]
      attacker_names = attackers.map { |a| a[:attacker_data][:name] }.join(", ")
      log_event("!! #{attacker_names} gang up on #{target_name}")
    end

    # Resolve each attack: drain energy from defender, give to attacker
    attacks.each_value do |attack|
      attacker_data = attack[:attacker_data]
      target_data   = attack[:target_data]

      next if attacker_data[:energy] <= 0
      next if target_data[:energy] <= 0

      drain = [1, attacker_data[:energy] / target_data[:energy]].max
      target_data[:energy]   -= drain
      attacker_data[:energy] += drain

      log_event("! #{attacker_data[:name]} drained #{drain} energy from #{target_data[:name]} (#{target_data[:energy]} remaining)")
    end

    @_absorb_intents.clear
  end

  def cull_dead_robots
    @_robot_data.select { |_, d| d[:energy] <= 0 }.each do |path, data|
      log_event("x #{data[:name]} ran out of energy and perished")
      @_robot_data.delete(path)
      @creatures.delete(path)
      release_icon(path)
      StateStore.delete_robot(path)
    end
  end

  def update_fortifications(prev_positions)
    # Build map of which robot name occupies which cell
    occupied = {}
    @_robot_data.each_value { |d| occupied[[d[:x], d[:y]]] = d[:name] }

    # For each robot: check if it stayed in place
    @_robot_data.each do |path, data|
      key = [data[:x], data[:y]]
      prev = prev_positions[path]
      stayed = prev && prev == key
      cell = @_territory[key]
      next unless cell

      if cell[:owner_name] == data[:name]
        # Owner sitting on own territory: increment strength
        cell[:strength] = (cell[:strength] || 0) + 1 if stayed
      elsif (cell[:strength] || 0) > 0
        # Rival on fortified territory: advance siege
        if cell[:siege_by] == data[:name]
          cell[:siege_progress] = (cell[:siege_progress] || 0) + 1 if stayed
        else
          cell[:siege_by] = data[:name]
          cell[:siege_progress] = stayed ? 1 : 0
        end

        if (cell[:siege_progress] || 0) >= cell[:strength]
          @_territory[key] = new_territory_cell(data)
        end
      end
    end

    # Reset siege on cells where the besieging robot left
    @_territory.each do |key, cell|
      next unless cell[:siege_by]
      unless occupied[key] == cell[:siege_by]
        cell[:siege_by] = nil
        cell[:siege_progress] = 0
      end
    end
  end

  def check_encounters
    entries = @_robot_data.to_a

    entries.each do |path_a, data_a|
      creature_a = @creatures[path_a]
      next unless creature_a

      entries.each do |path_b, data_b|
        next if path_a == path_b
        next unless (data_a[:x] - data_b[:x]).abs <= 1 && (data_a[:y] - data_b[:y]).abs <= 1

        result = safe_encounter(creature_a, data_b)
        resolve_actions(path_a, Array(result).compact) if result
      end
    end
  end

  def safe_encounter(creature_a, data_b)
    creature_a.encounter(data_b[:name], data_b[:icon])
  rescue => e
    LOGGER.error("Encounter error for #{creature_a.name}: #{e.message}")
    nil
  end

  def assign_icon(path)
    used = @used_icons.values.to_set
    icon = ICON_POOL.find { |i| !used.include?(i) }
    return nil unless icon

    @used_icons[path] = icon
    icon
  end

  def release_icon(path)
    @used_icons.delete(path)
  end

  def log_event(msg)
    StateStore.log_event(msg, tick: StateStore.tick_count)
  end
end
