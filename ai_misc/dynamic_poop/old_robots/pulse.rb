# robots/pulse.rb — Auto-generated: random movement, leaves markers
class Pulse < Creature
  def name        = "Pulse"
  def color       = :white
  def max_energy  = 71

  def tick(state, neighbors, world)
    # 60% territory-guided, 40% original movement pattern
    if rand < 0.6
      dx, dy = territory_suggest_move(state, world)
    else
    dx, dy = [[-1,0],[1,0],[0,-1],[0,1],[1,1],[-1,-1]].sample
    end
    actions = [{ move: [dx, dy] }]

    if state[:age] % 4 == 0
      actions << { say: "How does ticking work, anyway?" }
    end

    actions << { place_marker: %w[o x . * #].sample }

    actions
  end

  def encounter(other_name, other_icon)
    { say: "Fascinating! Tell me about yourself, #{other_name}!" }
  end
end
