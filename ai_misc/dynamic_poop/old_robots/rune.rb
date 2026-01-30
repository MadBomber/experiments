# robots/rune.rb — Auto-generated: orbital movement, no special ability
class Rune < Creature
  def name        = "Rune"
  def color       = :yellow
  def max_energy  = 64

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

    if state[:age] % 20 == 0
      actions << { say: "..." }
    end

    actions
  end

  def encounter(other_name, other_icon)
    { say: "Oh! Sorry, #{other_name}... didn't see you there." }
  end
end
