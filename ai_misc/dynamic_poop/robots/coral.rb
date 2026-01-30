# robots/coral.rb — Auto-generated: spiral movement, leaves markers
class Coral < Creature
  def name        = "Coral"
  def color       = :red
  def max_energy  = 81

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

    if state[:age] % 20 == 0
      actions << { say: "..." }
    end

    actions << { place_marker: %w[o x . * #].sample }

    actions
  end

  def encounter(other_name, other_icon)
    { say: "Oh! Sorry, #{other_name}... didn't see you there." }
  end
end
