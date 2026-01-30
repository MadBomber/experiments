# robots/byte.rb — Auto-generated: random movement, absorbs neighbors
class Byte < Creature
  def name        = "Byte"
  def color       = :red
  def max_energy  = 86

  def tick(state, neighbors, world)
    # 60% territory-guided, 40% original movement pattern
    if rand < 0.6
      dx, dy = territory_suggest_move(state, world)
    else
    dx, dy = [[-1,0],[1,0],[0,-1],[0,1],[1,1],[-1,-1]].sample
    end
    actions = [{ move: [dx, dy] }]

    if state[:age] % 4 == 0
      actions << { say: "What is that marker over there?" }
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
