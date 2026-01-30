# robots/ember.rb — Auto-generated: orbital movement, absorbs neighbors
class Ember < Creature
  def name        = "Ember"
  def color       = :red
  def max_energy  = 100

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

    if state[:age] % 10 == 0
      actions << { say: "I own this grid!" }
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
