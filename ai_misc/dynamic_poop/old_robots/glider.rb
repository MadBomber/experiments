# robots/glider.rb — Auto-generated: bouncing movement, absorbs neighbors
class Glider < Creature
  def name        = "Glider"
  def color       = :green
  def max_energy  = 95

  def tick(state, neighbors, world)
    # 60% territory-guided, 40% original movement pattern
    if rand < 0.6
      dx, dy = territory_suggest_move(state, world)
    else
    @bounce_dx ||= 1
    @bounce_dy ||= 1
    @bounce_dx = -@bounce_dx if state[:x] <= 1 || state[:x] >= world[:width] - 2
    @bounce_dy = -@bounce_dy if state[:y] <= 1 || state[:y] >= world[:height] - 2
    dx, dy = @bounce_dx, @bounce_dy
    end
    actions = [{ move: [dx, dy] }]

    if state[:age] % 10 == 0
      actions << { say: "No one can stop me!" }
    end

    if neighbors.any? { |n| n[:distance] <= 1.5 }
      actions << { absorb: true }
    end

    actions
  end

  def encounter(other_name, other_icon)
    { say: "Out of my way, #{other_name}!" }
  end
end
