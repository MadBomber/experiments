# frozen_string_literal: true

# Shared setup for every demo app in this directory.
#
# Loading this file at the top of a demo gives it:
#   - the BayesianInference library
#   - the BayesianInference namespace included, so demos can reference
#     Prior, Posterior, TimeSeriesPredictor, LlmPriorElicitor, etc.
#     without the module prefix
#   - the UI module of terminal presentation helpers

require_relative '../lib/bayesian_inference'

include BayesianInference

# Terminal UI elements shared by the demo apps.
#
# Every method returns a String (nothing prints), so each one can be
# tested in isolation; demos decide when and what to puts. ANSI color
# is applied only when STDOUT is a terminal and NO_COLOR is not set.
module UI
  WIDTH = 70

  STYLES = {
    bold:    "\e[1m",
    dim:     "\e[2m",
    red:     "\e[31m",
    green:   "\e[32m",
    yellow:  "\e[33m",
    blue:    "\e[34m",
    magenta: "\e[35m",
    cyan:    "\e[36m"
  }.freeze
  RESET = "\e[0m"

  module_function

  def color? = $stdout.tty? && ENV['NO_COLOR'].nil?

  # Wrap text in ANSI styles (no-op when color is off)
  def paint(text, *styles)
    return text.to_s unless color?

    "#{styles.map { STYLES.fetch(it) }.join}#{text}#{RESET}"
  end

  # Double-ruled box holding a title and optional subtitle
  def banner(title, subtitle = nil)
    inner = WIDTH - 2
    lines = ["╔#{'═' * inner}╗", "║#{title.center(inner)}║"]
    lines << "║#{subtitle.center(inner)}║" if subtitle
    lines << "╚#{'═' * inner}╝"
    paint(lines.join("\n"), :bold, :cyan)
  end

  # ── Title ────────── section divider
  def section(title)
    rule = '─' * [WIDTH - title.length - 4, 0].max
    "\n#{paint("── #{title} ", :bold)}#{paint(rule, :dim)}\n"
  end

  # Aligned "Label  value" row
  def kv(label, value, label_width: 14, indent: 2)
    "#{' ' * indent}#{paint("#{label}:".ljust(label_width + 1), :dim)} #{value}"
  end

  # "42.3%" with fixed width so columns line up
  def pct(probability) = format('%5.1f%%', probability * 100)

  # Horizontal bar: filled portion styled, remainder dim
  def bar(fraction, width: 24, style: :cyan)
    filled = (fraction.clamp(0.0, 1.0) * width).round
    paint('█' * filled, style) + paint('░' * (width - filled), :dim)
  end

  # Default color scheme for signed outcomes: negative red,
  # zero yellow, positive green
  def signed_style(outcome)
    if outcome.negative? then :red
    elsif outcome.positive? then :green
    else :yellow
    end
  end

  # Bar chart of an outcome => probability distribution.
  # pairs:  [[outcome, probability], ...]
  # labels: {outcome => "human label"}
  # The most likely outcome gets a ◀ marker.
  def distribution(pairs, labels: {}, width: 24)
    best = pairs.max_by { it[1] }&.first

    pairs.map do |outcome, prob|
      row = "  #{outcome.to_s.rjust(3)}  #{pct(prob)}  " \
            "#{bar(prob, width:, style: signed_style(outcome))}  " \
            "#{labels[outcome]}"
      outcome == best ? "#{row} #{paint('◀', :bold)}" : row
    end.join("\n")
  end

  # Bar chart of raw sample counts (outcome => count), scaled so the
  # largest count fills the bar.
  def tally_chart(samples, labels: {}, width: 24)
    counts = samples.tally.sort_by { it.first }
    total = samples.size.to_f
    max = counts.map { it[1] }.max

    counts.map do |outcome, count|
      "  #{outcome.to_s.rjust(3)}  #{count.to_s.rjust(4)}  #{pct(count / total)}  " \
        "#{bar(count / max.to_f, width:, style: signed_style(outcome))}  " \
        "#{labels[outcome]}"
    end.join("\n")
  end

  # Verdict tag comparing a prediction against the expected outcome
  def verdict(predicted, expected)
    if predicted == expected
      paint('✔ as expected', :green)
    else
      paint("✘ expected #{expected}", :red)
    end
  end

  # Headline stats for a posterior: MAP outcome, confidence, entropy
  def posterior_stats(posterior, labels: {})
    best = posterior.max_outcome
    best_label = labels[best] ? " — #{labels[best]}" : ''

    [
      kv('Most likely', "#{paint(best, :bold)}#{best_label} at #{pct(posterior.probability(best)).strip}"),
      kv('Confidence', pct(posterior.confidence).strip),
      kv('Entropy', "#{format('%.3f', posterior.entropy)} bits " \
                    "#{paint('(0 = certain, 2.322 = coin toss over 5 outcomes)', :dim)}")
    ].join("\n")
  end

  # Full panel: headline stats plus the probability distribution chart
  def posterior_panel(posterior, labels: {}, width: 24)
    "#{posterior_stats(posterior, labels:)}\n\n#{distribution(posterior.to_a, labels:, width:)}"
  end

  # Bulleted list under a bold heading, e.g. for takeaways
  def bullet_list(title, items)
    "#{paint(title, :bold)}\n#{items.map { "  • #{it}" }.join("\n")}"
  end

  # Dim parenthetical note
  def note(text) = paint(text, :dim)
end
