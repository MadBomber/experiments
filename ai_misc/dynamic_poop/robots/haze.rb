# robots/haze.rb — Auto-generated: zigzag movement, no special ability
class Haze < Creature
  def name        = "Haze"
  def color       = :blue
  def max_energy  = 148

  def tick(state, neighbors, world)
    # 60% territory-guided, 40% original movement pattern
    if rand < 0.6
      dx, dy = territory_suggest_move(state, world)
    else
    step = state[:age] % 4
    dx = step < 2 ? 1 : -1
    dy = step.even? ? 1 : -1
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
