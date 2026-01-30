# robots/philosopher.rb — Stays still, broadcasts wisdom each tick
class Philosopher < Creature
  QUOTES = [
    "The unexamined grid is not worth living on.",
    "I tick, therefore I am.",
    "One cannot step in the same cell twice.",
    "To move is to change; to be perfect is to have moved often.",
    "Hell is other robots.",
    "The only true wisdom is knowing you know nothing of the next tick.",
    "We are what we repeatedly do. Excellence is a habit.",
    "Man is condemned to be free... to move in four directions.",
    "Existence precedes essence. Ticking precedes thinking.",
    "What does not kill me makes me stronger... unless it absorbs me.",
  ].freeze

  def name        = "Philosopher"
  def color       = :magenta
  def max_energy  = 80

  def tick(state, neighbors, world)
    quote = QUOTES[state[:age] % QUOTES.size]
    actions = [{ say: quote }]

    # Slow contemplative territory walk every 3 ticks
    if (state[:age] % 3).zero?
      dx, dy = territory_suggest_move(state, world, protect_weight: 0.2)
      actions << { move: [dx, dy] }
    end

    actions
  end

  def encounter(other_name, other_icon)
    { say: "Ah, #{other_name}. Let us contemplate existence together." }
  end
end
