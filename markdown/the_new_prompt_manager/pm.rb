# frozen_string_literal: true

require 'date'
require 'yaml'
require 'erb'
require 'open3'
require 'ostruct'

# PM (PromptManager) parses YAML metadata from markdown strings or files.
# Processing pipeline: extract metadata → shell expansion → ERB on demand.
module PM
  VERSION = '0.1.0'

  METADATA_REGEXP = /
    \A
    [[:space:]]*
    ---
    (?<metadata>.*?)
    ---
    [[:blank:]]*$[\n\r]?
    (?<content>.*)
    \z
  /mx

  ENV_VAR_REGEXP    = /\$\{([A-Z_][A-Z0-9_]*)\}|\$([A-Z_][A-Z0-9_]*)/
  COMMAND_START     = '$('

  METADATA_DEFAULTS = { 'shell' => true, 'erb' => true }.freeze

  # OpenStruct-based metadata with predicate methods for boolean keys.
  class Metadata < OpenStruct
    def initialize(hash = {})
      super(hash)
      hash.each do |key, value|
        if value.is_a?(TrueClass) || value.is_a?(FalseClass)
          define_singleton_method(:"#{key}?") { send(key) }
        end
      end
    end
  end

  Parsed = Struct.new(:metadata, :content, keyword_init: true) do
    def [](key)
      metadata[key]
    end

    # Returns the prompt content with ERB tags expanded.
    # ERB always has access to Ruby builtins (require, Time.now, etc.).
    # When metadata defines parameters, they are available as variables.
    # With a Hash argument, merges those values over the defaults.
    # Raises if any required parameters (default: null) are not provided.
    # When metadata has erb: false, returns content without ERB processing.
    def to_s(values = {})
      return content unless metadata.erb?

      defaults = metadata.parameters || {}
      params = defaults.merge(values.transform_keys(&:to_s))

      missing = params.select { |_, v| v.nil? }.keys
      unless missing.empty?
        raise ArgumentError, "Missing required parameters: #{missing.join(', ')}"
      end

      context = OpenStruct.new(params)
      ERB.new(content).result(context.instance_eval { binding })
    end
  end

  # Parses metadata and content from a file.
  # Extracts metadata first to check shell/erb flags.
  # Runs shell expansion on content when shell: true (default).
  # Adds `directory`, `name`, `created_at`, and `modified_at` to the metadata.
  def self.parse_file(pathname)
    raw = File.read(pathname)
    parsed = parse(raw)

    content = if parsed.metadata.shell?
                expand_shell(parsed.content)
              else
                parsed.content
              end

    path = File.expand_path(pathname)
    stat = File.stat(path)
    metadata = build_metadata(
      parsed.metadata.to_h.merge(
        directory:   File.dirname(path),
        name:        File.basename(path),
        created_at:  stat.birthtime,
        modified_at: stat.mtime
      )
    )
    Parsed.new(metadata: metadata, content: content)
  end

  # Parses metadata and content from a string.
  # Does not perform shell expansion.
  def self.parse(string)
    match = string.match(METADATA_REGEXP)
    if match
      Parsed.new(metadata: build_metadata(YAML.safe_load(match[:metadata], permitted_classes: [Date, Time])), content: match[:content])
    else
      Parsed.new(metadata: build_metadata({}), content: string)
    end
  end

  # Builds a Metadata object with defaults for shell and erb.
  def self.build_metadata(hash)
    Metadata.new(METADATA_DEFAULTS.merge(hash.transform_keys(&:to_s)))
  end
  private_class_method :build_metadata

  # Expands shell references in a string.
  # $ENVAR and ${ENVAR} are replaced with the environment variable value.
  # $(command) is executed and replaced with its stdout.
  def self.expand_shell(string)
    result = expand_commands(string)
    expand_env_vars(result)
  end

  # Replaces $(command) with the command's stdout.
  # Handles nested parentheses in commands.
  def self.expand_commands(string)
    result = string.dup
    pos = 0

    while (start = result.index(COMMAND_START, pos))
      depth = 0
      i = start + 1

      while i < result.length
        if result[i] == '('
          depth += 1
        elsif result[i] == ')'
          depth -= 1
          if depth == 0
            command = result[(start + 2)...i]
            output, status = Open3.capture2(command)
            output = output.chomp
            unless status.success?
              raise "Shell command failed (exit #{status.exitstatus}): #{command}"
            end
            result[start..i] = output
            pos = start + output.length
            break
          end
        end
        i += 1
      end

      break if depth != 0
    end

    result
  end
  private_class_method :expand_commands

  # Replaces $ENVAR and ${ENVAR} with environment variable values.
  # Missing variables are replaced with an empty string.
  def self.expand_env_vars(string)
    string.gsub(ENV_VAR_REGEXP) { ENV.fetch($1 || $2, '') }
  end
  private_class_method :expand_env_vars
end
