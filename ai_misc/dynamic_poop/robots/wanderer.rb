# robots/wanderer.rb — Moves randomly, greets neighbors
class Wanderer < Creature
  def name        = "Wanderer"
  def color       = :cyan
  def max_energy  = 100

  def tick(state, neighbors, world)
    dx, dy = if rand < 0.7
               territory_suggest_move(state, world, protect_weight: 0.1)
             else
               [[-1, 0], [1, 0], [0, -1], [0, 1]].sample
             end
    actions = [{ move: [dx, dy] }]

    if neighbors.any? && state[:age] % 5 == 0
      nearest = neighbors.min_by { |n| n[:distance] }
      actions << { say: "Hello, #{nearest[:name]}!" }
    end

    actions
  end

  def encounter(other_name, other_icon)
    { say: "Nice to meet you, #{other_name}!" }
  end
end
