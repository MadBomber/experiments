# robots/moss.rb — Auto-generated: random movement, leaves markers
class Moss < Creature
  def name        = "Moss"
  def color       = :white
  def max_energy  = 76

  def tick(state, neighbors, world)
    # 60% territory-guided, 40% original movement pattern
    if rand < 0.6
      dx, dy = territory_suggest_move(state, world)
    else
    dx, dy = [[-1,0],[1,0],[0,-1],[0,1],[1,1],[-1,-1]].sample
    end
    actions = [{ move: [dx, dy] }]

    if state[:age] % 10 == 0
      actions << { say: "I own this grid!" }
    end

    actions << { place_marker: %w[o x . * #].sample }

    actions
  end

  def encounter(other_name, other_icon)
    { say: "Out of my way, #{other_name}!" }
  end
end
