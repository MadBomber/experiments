# frozen_string_literal: true

require "zeitwerk"
require_relative "creature"

# Loads robot files from the robots/ directory using Zeitwerk for
# autoloading and hot-reloading. Each robot file defines a class
# that inherits from Creature (e.g., class Wanderer < Creature).
#
# On reload: Zeitwerk unloads all robot constants, re-sets autoloads,
# then eager_load brings them all back with fresh class definitions.
class RobotLoader
  attr_reader :robots_dir

  def initialize(robots_dir)
    @robots_dir = robots_dir
    @loader = Zeitwerk::Loader.new
    @loader.tag = "robots"
    @loader.push_dir(robots_dir)
    @loader.enable_reloading
    @loader.setup
    LOGGER.info("RobotLoader: zeitwerk configured for #{robots_dir}")
  end

  # Eager-load all robot files and return a hash of { path => creature_instance }.
  def load_all
    @loader.eager_load
    build_creatures
  end

  # Reload all robot files (unload + re-autoload + eager load).
  # Returns a fresh hash of { path => creature_instance }.
  def reload_all
    @loader.reload
    @loader.eager_load
    build_creatures
  rescue => e
    LOGGER.error("RobotLoader: reload failed: #{e.message}")
    {}
  end

  private

  # Scan the robots directory, map each file to its zeitwerk-managed class,
  # instantiate a creature, and return { path => creature_instance }.
  def build_creatures
    creatures = {}
    Dir.glob(File.join(@robots_dir, "*.rb")).sort.each do |path|
      basename = File.basename(path, ".rb")
      class_name = zeitwerk_camelize(basename)

      klass = Object.const_get(class_name)
      unless klass < Creature
        LOGGER.warn("RobotLoader: #{class_name} in #{path} does not inherit from Creature, skipping")
        next
      end

      creatures[path] = klass.new
    rescue NameError => e
      LOGGER.error("RobotLoader: constant #{class_name} not found for #{path}: #{e.message}")
    rescue => e
      LOGGER.error("RobotLoader: failed to instantiate #{class_name} from #{path}: #{e.message}")
    end
    creatures
  end

  # Convert a snake_case basename to CamelCase (matching zeitwerk's default inflector).
  def zeitwerk_camelize(basename)
    basename.split("_").map(&:capitalize).join
  end
end
