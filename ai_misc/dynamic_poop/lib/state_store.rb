# frozen_string_literal: true

require "mudis"

# Central state management layer backed by Mudis (in-memory LRU cache).
# All simulation data flows through this module. Domain-specific API
# wrapping Mudis namespaces for world, robots, territory, markers,
# events, broadcasts, and per-robot memory.
module StateStore
  NS_WORLD     = "world"
  NS_ROBOTS    = "robots"
  NS_TERRITORY = "territory"
  NS_MARKERS   = "markers"
  NS_EVENTS    = "events"
  NS_BROADCAST = "broadcast"

  class << self
    # ------------------------------------------------------------------
    # Setup / teardown
    # ------------------------------------------------------------------

    def setup!(width: 40, height: 20)
      Mudis.configure do |c|
        c.serializer = Marshal
        c.compress   = false
      end

      Mudis.start_expiry_thread(interval: 10)

      # Seed world dimensions
      Mudis.write("dimensions", { width: width, height: height }, namespace: NS_WORLD)
      Mudis.write("tick_count", 0, namespace: NS_WORLD)

      # Seed empty collections
      Mudis.write("_paths", [], namespace: NS_ROBOTS)
      Mudis.write("grid", {}, namespace: NS_TERRITORY)
      Mudis.write("list", [], namespace: NS_MARKERS)
      Mudis.write("log", [], namespace: NS_EVENTS)

      LOGGER.info("StateStore: initialized (#{width}x#{height}, serializer=Marshal)")
    end

    def reset!
      Mudis.stop_expiry_thread
      Mudis.reset!
      LOGGER.info("StateStore: reset complete")
    end

    # ------------------------------------------------------------------
    # World
    # ------------------------------------------------------------------

    def tick_count
      Mudis.read("tick_count", namespace: NS_WORLD) || 0
    end

    def increment_tick
      Mudis.update("tick_count", namespace: NS_WORLD) { |v| (v || 0) + 1 }
      tick_count
    end

    def dimensions
      Mudis.read("dimensions", namespace: NS_WORLD) || { width: 40, height: 20 }
    end

    def dimensions=(hash)
      Mudis.write("dimensions", hash, namespace: NS_WORLD)
    end

    def width
      dimensions[:width]
    end

    def height
      dimensions[:height]
    end

    # ------------------------------------------------------------------
    # Robots (per-path keys + path registry)
    # ------------------------------------------------------------------

    def all_robot_data
      paths = Mudis.read("_paths", namespace: NS_ROBOTS) || []
      result = {}
      paths.each do |path|
        data = Mudis.read(path, namespace: NS_ROBOTS)
        result[path] = data if data
      end
      result
    end

    def robot_data(path)
      Mudis.read(path, namespace: NS_ROBOTS)
    end

    def write_robot(path, data)
      Mudis.write(path, data, namespace: NS_ROBOTS)
      register_path(path)
    end

    def update_robot(path)
      current = robot_data(path)
      return unless current

      updated = yield(current)
      Mudis.write(path, updated, namespace: NS_ROBOTS)
      updated
    end

    def delete_robot(path)
      Mudis.delete(path, namespace: NS_ROBOTS)
      unregister_path(path)
    end

    def write_all_robots(data_hash)
      data_hash.each { |path, data| Mudis.write(path, data, namespace: NS_ROBOTS) }
      Mudis.write("_paths", data_hash.keys, namespace: NS_ROBOTS)
    end

    # ------------------------------------------------------------------
    # Territory (single key, bulk hash)
    # ------------------------------------------------------------------

    def territory
      Mudis.read("grid", namespace: NS_TERRITORY) || {}
    end

    def territory=(hash)
      Mudis.write("grid", hash, namespace: NS_TERRITORY)
    end

    def territory_at(x, y)
      territory[[x, y]]
    end

    def claim_territory(x, y, cell_data)
      Mudis.update("grid", namespace: NS_TERRITORY) do |grid|
        grid ||= {}
        grid[[x, y]] = cell_data
        grid
      end
    end

    def territory_summary
      grid = territory
      counts = Hash.new(0)
      grid.each_value { |cell| counts[cell[:owner_name]] += 1 }
      counts
    end

    # ------------------------------------------------------------------
    # Markers (single key, array)
    # ------------------------------------------------------------------

    def markers
      Mudis.read("list", namespace: NS_MARKERS) || []
    end

    def markers=(array)
      Mudis.write("list", array, namespace: NS_MARKERS)
    end

    # ------------------------------------------------------------------
    # Events (single key, bounded array)
    # ------------------------------------------------------------------

    def event_log
      Mudis.read("log", namespace: NS_EVENTS) || []
    end

    def log_event(msg, tick:, max: 50)
      LOGGER.info("[t#{tick}] #{msg}")
      Mudis.update("log", namespace: NS_EVENTS) do |log|
        log ||= []
        log << "[t#{tick}] #{msg}"
        log.shift while log.size > max
        log
      end
    end

    # ------------------------------------------------------------------
    # Robot broadcast (per-robot keys with TTL)
    # ------------------------------------------------------------------

    def broadcast(robot_name, message)
      Mudis.write(robot_name, message, namespace: NS_BROADCAST, expires_in: 30)
    end

    def read_broadcast(robot_name)
      Mudis.read(robot_name, namespace: NS_BROADCAST)
    end

    def all_broadcasts
      keys = Mudis.keys(namespace: NS_BROADCAST)
      result = {}
      keys.each do |key|
        val = Mudis.read(key, namespace: NS_BROADCAST)
        result[key] = val if val
      end
      result
    end

    # ------------------------------------------------------------------
    # Robot memory (per-robot namespace)
    # ------------------------------------------------------------------

    def store_memory(robot_name, key, value, expires_in: nil)
      ns = "memory:#{robot_name}"
      opts = { namespace: ns }
      opts[:expires_in] = expires_in if expires_in
      Mudis.write(key, value, **opts)
    end

    def recall_memory(robot_name, key)
      Mudis.read(key, namespace: "memory:#{robot_name}")
    end

    def memory_keys(robot_name)
      Mudis.keys(namespace: "memory:#{robot_name}")
    end

    def clear_memory(robot_name)
      Mudis.clear_namespace(namespace: "memory:#{robot_name}")
    end

    private

    def register_path(path)
      Mudis.update("_paths", namespace: NS_ROBOTS) do |paths|
        paths ||= []
        paths | [path]
      end
    end

    def unregister_path(path)
      Mudis.update("_paths", namespace: NS_ROBOTS) do |paths|
        paths ||= []
        paths - [path]
      end
    end
  end
end
