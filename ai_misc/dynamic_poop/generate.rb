#!/usr/bin/env ruby
# frozen_string_literal: true

# Procedurally generates new robot .rb files from randomized traits.
# Each generated file defines a class inheriting from Creature,
# compatible with Zeitwerk autoloading.
#
# Usage:
#   ruby generate.rb             # random name
#   ruby generate.rb "Dancer"    # specific name

ROBOTS_DIR = File.join(__dir__, "robots")

MOVEMENT_PATTERNS = {
  zigzag: {
    code: <<~'RUBY',
      step = state[:age] % 4
      dx = step < 2 ? 1 : -1
      dy = step.even? ? 1 : -1
    RUBY
    desc: "zigzag"
  },
  spiral: {
    code: <<~'RUBY',
      dirs = [[1,0],[0,1],[-1,0],[0,-1]]
      phase = (state[:age] / 3) % 4
      dx, dy = dirs[phase]
    RUBY
    desc: "spiral"
  },
  orbit: {
    code: <<~'RUBY',
      angle = state[:age] * 0.5
      dx = (Math.cos(angle)).round
      dy = (Math.sin(angle)).round
    RUBY
    desc: "orbital"
  },
  bounce: {
    code: <<~'RUBY',
      @bounce_dx ||= 1
      @bounce_dy ||= 1
      @bounce_dx = -@bounce_dx if state[:x] <= 1 || state[:x] >= world[:width] - 2
      @bounce_dy = -@bounce_dy if state[:y] <= 1 || state[:y] >= world[:height] - 2
      dx, dy = @bounce_dx, @bounce_dy
    RUBY
    desc: "bouncing"
  },
  random: {
    code: <<~'RUBY',
      dx, dy = [[-1,0],[1,0],[0,-1],[0,1],[1,1],[-1,-1]].sample
    RUBY
    desc: "random"
  }
}.freeze

PERSONALITIES = {
  friendly: {
    encounter_response: '"Hey there, %{name}! Great to see you!"',
    say_frequency: 6,
    say_messages: [
      '"What a beautiful tick!"',
      '"Life is good on this grid!"',
      '"Anyone want to be friends?"'
    ]
  },
  aggressive: {
    encounter_response: '"Out of my way, %{name}!"',
    say_frequency: 10,
    say_messages: [
      '"I own this grid!"',
      '"Come at me!"',
      '"No one can stop me!"'
    ],
    absorb: true
  },
  shy: {
    encounter_response: '"Oh! Sorry, %{name}... didn\'t see you there."',
    say_frequency: 20,
    say_messages: [
      '"..."',
      '"*shuffles quietly*"',
      '"I hope no one notices me."'
    ]
  },
  curious: {
    encounter_response: '"Fascinating! Tell me about yourself, %{name}!"',
    say_frequency: 4,
    say_messages: [
      '"What is that marker over there?"',
      '"I wonder what\'s beyond the grid..."',
      '"How does ticking work, anyway?"'
    ]
  }
}.freeze

ABILITIES = {
  marker: {
    code: <<~'RUBY',
      actions << { place_marker: %w[o x . * #].sample }
    RUBY
    desc: "leaves markers"
  },
  absorber: {
    code: <<~'RUBY',
      if neighbors.any? { |n| n[:distance] <= 1.5 }
        actions << { absorb: true }
      end
    RUBY
    desc: "absorbs neighbors"
  },
  none: {
    code: "",
    desc: "no special ability"
  }
}.freeze

COLORS  = %i[red green yellow blue magenta cyan white].freeze

NAMES = %w[
  Dancer Sprinter Hopper Glider Drifter Scout Shade
  Spark Pulse Echo Ripple Frost Ember Moss Thorn
  Coral Rune Glyph Pixel Byte Quark Nova Haze
].freeze

def indent(text, spaces)
  prefix = " " * spaces
  text.lines.map { |line| "#{prefix}#{line}" }.join
end

def generate_robot(name = nil)
  name      ||= NAMES.sample
  color       = COLORS.sample
  energy      = rand(60..150)
  movement    = MOVEMENT_PATTERNS.values.sample
  personality = PERSONALITIES.values.sample
  ability     = ABILITIES.values.sample

  say_msgs      = personality[:say_messages]
  say_freq      = personality[:say_frequency]
  encounter_msg = personality[:encounter_response]

  movement_code = indent(movement[:code].strip, 4)
  ability_code  = ability[:code].strip
  ability_code  = indent(ability_code, 4) unless ability_code.empty?

  # Zeitwerk expects CamelCase class name matching the filename
  class_name = name.split("_").map(&:capitalize).join

  lines = []
  lines << "# robots/#{name.downcase}.rb — Auto-generated: #{movement[:desc]} movement, #{ability[:desc]}"
  lines << "class #{class_name} < Creature"
  lines << "  def name        = \"#{name}\""
  lines << "  def color       = :#{color}"
  lines << "  def max_energy  = #{energy}"
  lines << ""
  lines << "  def tick(state, neighbors, world)"
  lines << "    # 60% territory-guided, 40% original movement pattern"
  lines << "    if rand < 0.6"
  lines << "      dx, dy = territory_suggest_move(state, world)"
  lines << "    else"
  lines << movement_code
  lines << "    end"
  lines << "    actions = [{ move: [dx, dy] }]"
  lines << ""
  lines << "    if state[:age] % #{say_freq} == 0"
  lines << "      actions << { say: #{say_msgs.sample} }"
  lines << "    end"
  lines << ""
  lines << ability_code unless ability_code.empty?
  lines << ""         unless ability_code.empty?
  lines << "    actions"
  lines << "  end"
  lines << ""
  lines << "  def encounter(other_name, other_icon)"
  lines << "    { say: #{encounter_msg.gsub('%{name}', "\#{other_name}")} }"
  lines << "  end"
  lines << "end"

  code = lines.join("\n") + "\n"

  filename = "#{name.downcase.gsub(/[^a-z0-9]/, '_')}.rb"
  filepath = File.join(ROBOTS_DIR, filename)

  if File.exist?(filepath)
    $stderr.puts "Robot file already exists: #{filepath}"
    return nil
  end

  File.write(filepath, code)
  puts "Generated #{name} (#{color}) -> #{filepath}"
  filepath
end

if __FILE__ == $0
  name = ARGV[0]
  generate_robot(name)
end
