# robots/scout.rb — Auto-generated: zigzag movement, absorbs neighbors
class Scout < Creature
  def name        = "Scout"
  def color       = :yellow
  def max_energy  = 81

  def tick(state, neighbors, world)
    # 60% territory-guided, 40% original movement pattern
    if rand < 0.6
      dx, dy = territory_suggest_move(state, world)
    else
    step = state[:age] % 4
    dx = step < 2 ? 1 : -1
    dy = step.even? ? 1 : -1
    end
    actions = [{ move: [dx, dy] }]

    if state[:age] % 4 == 0
      actions << { say: "How does ticking work, anyway?" }
    end

    if neighbors.any? { |n| n[:distance] <= 1.5 }
      actions << { absorb: true }
    end

    actions
  end

  def encounter(other_name, other_icon)
    { say: "Fascinating! Tell me about yourself, #{other_name}!" }
  end
end
