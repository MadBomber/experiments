# robots/builder.rb — Places colored markers in patterns
class Builder < Creature
  PATTERNS = [
    [1, 0], [0, 1], [-1, 0], [0, -1]  # square walk
  ].freeze

  MARKER_SYMBOLS = %w[# * + = ~].freeze

  def name        = "Builder"
  def color       = :green
  def max_energy  = 120

  def tick(state, neighbors, world)
    # Every 20 ticks, relocate toward unclaimed territory for new build sites
    if (state[:age] % 20).zero? && state[:age] > 0
      explore = territory_explore_direction(state, world)
      if explore
        dx, dy = explore
        return [{ move: [dx, dy] }, { place_marker: MARKER_SYMBOLS.sample }]
      end
    end

    step = state[:age] % PATTERNS.size
    dx, dy = PATTERNS[step]
    symbol = MARKER_SYMBOLS[state[:age] % MARKER_SYMBOLS.size]

    [
      { move: [dx, dy] },
      { place_marker: symbol }
    ]
  end

  def encounter(other_name, other_icon)
    { say: "Building here, #{other_name}. Watch your step!" }
  end
end
