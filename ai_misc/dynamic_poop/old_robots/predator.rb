# robots/predator.rb — Chases nearest robot, absorbs on contact
class Predator < Creature
  def name        = "Predator"
  def color       = :red
  def max_energy  = 150

  def tick(state, neighbors, world)
    if neighbors.empty?
      dx, dy = territory_reclaim_direction(state, world) || [[-1, 1].sample, [-1, 1].sample]
      return { move: [dx, dy] }
    end

    target = neighbors.min_by { |n| n[:distance] }

    dx = case target[:direction]
         when :east  then 1
         when :west  then -1
         else 0
         end

    dy = case target[:direction]
         when :south then 1
         when :north then -1
         else 0
         end

    actions = [{ move: [dx, dy] }]

    if target[:distance] <= 1.5
      actions << { absorb: true }
      actions << { say: "Consumed #{target[:name]}!" }
    end

    actions
  end

  def encounter(other_name, other_icon)
    { say: "You look delicious, #{other_name}..." }
  end
end
