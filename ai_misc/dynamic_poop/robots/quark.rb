# robots/quark.rb — Auto-generated: spiral movement, no special ability
class Quark < Creature
  def name        = "Quark"
  def color       = :blue
  def max_energy  = 66

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

    if state[:age] % 10 == 0
      actions << { say: "Come at me!" }
    end

    actions
  end

  def encounter(other_name, other_icon)
    { say: "Out of my way, #{other_name}!" }
  end
end
