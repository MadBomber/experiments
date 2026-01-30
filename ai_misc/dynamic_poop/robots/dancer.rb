# robots/dancer.rb — Auto-generated: orbital movement, absorbs neighbors
class Dancer < Creature
  def name        = "Dancer"
  def color       = :cyan
  def max_energy  = 69

  def tick(state, neighbors, world)
    # 60% territory-guided, 40% original movement pattern
    if rand < 0.6
      dx, dy = territory_suggest_move(state, world)
    else
    angle = state[:age] * 0.5
    dx = (Math.cos(angle)).round
    dy = (Math.sin(angle)).round
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
