# robots/ripple.rb — Auto-generated: bouncing movement, absorbs neighbors
class Ripple < Creature
  def name        = "Ripple"
  def color       = :yellow
  def max_energy  = 127

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
