# robots/frost.rb — Auto-generated: bouncing movement, no special ability
class Frost < Creature
  def name        = "Frost"
  def color       = :white
  def max_energy  = 137

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

    if state[:age] % 20 == 0
      actions << { say: "*shuffles quietly*" }
    end

    actions
  end

  def encounter(other_name, other_icon)
    { say: "Oh! Sorry, #{other_name}... didn't see you there." }
  end
end
