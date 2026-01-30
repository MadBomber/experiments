# robots/oracle.rb — LLM-powered creature demonstrating introspection,
# strategic planning, and runtime method generation via chaos_to_the_rescue.
class Oracle < Creature
  def name       = "Oracle"
  def color      = :yellow
  def max_energy = 120

  def tick(state, neighbors, world)
    actions = []

    # Full LLM strategy every ~20 ticks
    if llm_available? && (state[:age] % 20).zero? && state[:age] > 0
      strategy = llm_strategize(state, neighbors, world, cooldown: 20)
      return strategy unless strategy.empty?
    end

    # Witty observation every ~10 ticks
    if llm_available? && (state[:age] % 10).zero? && state[:age] > 0
      stats = territory_stats(world)
      observation = llm_decide(
        "You are Oracle, a mystical robot in a grid world at tick #{world[:tick]}. " \
        "You have #{state[:energy]} energy and see #{neighbors.size} neighbors. " \
        "You own #{stats[:my_count]} of #{stats[:total_cells]} territory cells (#{stats[:coverage]}%). " \
        "Say something witty or mystical in under 40 characters.",
        cooldown: 10
      )
      actions << { say: observation } if observation
    end

    # Low energy: call an undefined method — chaos_to_the_rescue generates it
    if state[:energy] < 30
      begin
        vector = calculate_escape_vector(state[:x], state[:y], state[:energy])
        if vector.is_a?(Array) && vector.size == 2
          actions << { move: vector }
          actions << { say: "Escape vector engaged!" }
          return actions
        end
      rescue => _e
        # chaos_to_the_rescue unavailable, fall through to default movement
      end
    end

    # Fallback: move toward nearest neighbor or use territory-aware exploration
    if neighbors.any?
      nearest = neighbors.min_by { |n| n[:distance] }
      dx, dy = direction_to_delta(nearest[:direction])
      actions << { move: [dx, dy] }
    else
      dx, dy = territory_suggest_move(state, world, protect_weight: 0.3)
      actions << { move: [dx, dy] }
    end

    actions
  end

  def encounter(other_name, other_icon)
    if llm_available?
      greeting = llm_decide(
        "You are Oracle, a mystical robot. You just met #{other_name} (#{other_icon}). " \
        "Give a short mystical greeting under 50 characters.",
        cooldown: 5
      )
      return { say: greeting } if greeting
    end

    { say: "The stars aligned, #{other_name}..." }
  end

  private

  def direction_to_delta(direction)
    case direction
    when :north then [0, -1]
    when :south then [0, 1]
    when :east  then [1, 0]
    when :west  then [-1, 0]
    else [0, 0]
    end
  end
end
