# robots/mimic.rb — Copies movement pattern of last encountered robot
class Mimic < Creature
  def name        = "Mimic"
  def color       = :yellow
  def max_energy  = 100

  def initialize
    @last_seen_direction = nil
  end

  def tick(state, neighbors, world)
    if neighbors.any?
      nearest = neighbors.min_by { |n| n[:distance] }
      @last_seen_direction = nearest[:direction]
      dx, dy = direction_to_delta(@last_seen_direction)
      actions = [{ move: [dx, dy] }]
      actions << { say: "Mimicking #{nearest[:name]}..." } if state[:age] % 8 == 0
    elsif @last_seen_direction
      dx, dy = direction_to_delta(@last_seen_direction)
      actions = [{ move: [dx, dy] }]
    else
      # Alone with no memory — explore territory
      dx, dy = territory_suggest_move(state, world, protect_weight: 0.2)
      actions = [{ move: [dx, dy] }]
    end

    actions
  end

  def encounter(other_name, other_icon)
    { say: "I am now #{other_icon}... just kidding, I'm #{icon}." }
  end

  private

  def direction_to_delta(dir)
    case dir
    when :north then [0, -1]
    when :south then [0, 1]
    when :east  then [1, 0]
    when :west  then [-1, 0]
    else [0, 0]
    end
  end
end
