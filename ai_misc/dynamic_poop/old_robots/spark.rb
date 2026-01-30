# robots/spark.rb — Auto-generated: spiral movement, absorbs neighbors
class Spark < Creature
  def name        = "Spark"
  def color       = :green
  def max_energy  = 94

  def tick(state, neighbors, world)
    # 60% territory-guided, 40% original movement pattern
    if rand < 0.6
      dx, dy = territory_suggest_move(state, world)
    else
    dirs = [[1,0],[0,1],[-1,0],[0,-1]]
    phase = (state[:age] / 3) % 4
    dx, dy = dirs[phase]
    end
    actions = [{ move: [dx, dy] }]

    if state[:age] % 4 == 0
      actions << { say: "I wonder what's beyond the grid..." }
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
