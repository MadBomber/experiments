#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/lib/prose_score/report_formatter.rb
##  Desc: Renders a Scorer report as readable, optionally-colorized text
##        for the CLI.
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

module ProseScore
  class ReportFormatter
    BAR_WIDTH = 20
    ISSUES_SHOWN_PER_ANALYZER = 6

    ANSI = {
      reset: "\e[0m", bold: "\e[1m", dim: "\e[2m",
      green: "\e[32m", yellow: "\e[33m", red: "\e[31m", cyan: "\e[36m"
    }.freeze

    ANALYZER_LABELS = {
      conventions: 'Conventions',
      clarity: 'Clarity',
      coherence: 'Coherence & Organization',
      readability: 'Readability & Vocabulary',
      llm_judge: 'LLM Judge'
    }.freeze

    TRAIT_LABELS = { ideas: 'Ideas', organization: 'Organization', voice: 'Voice', word_choice: 'Word Choice' }.freeze

    def self.render(report, color: $stdout.tty?) = new(report, color:).render

    def initialize(report, color: true)
      @report = report
      @color = color
    end

    def render
      lines = [rule, header_line, rule, '']
      @report[:analyzers].each { |name, data| lines.concat(analyzer_lines(name, data)) }
      lines << rule
      lines.join("\n")
    end

    private

    def rule = colorize('-' * 63, :dim)

    def header_line
      label = colorize('PROSE SCORE', :bold)
      score = colorize(format('%5.1f%%', @report[:score]), score_color(@report[:score]))
      mode = colorize("(#{@report[:mode]})", :dim)
      "  #{label}#{' ' * 35}#{score}  #{mode}"
    end

    def analyzer_lines(name, data)
      label = (ANALYZER_LABELS[name] || name.to_s).ljust(24)
      score_text = colorize(format('%5.1f%%', data[:score]), score_color(data[:score]))
      count_text = count_label(name, data[:issues].size)

      lines = ["  #{label}  #{score_text}  #{bar(data[:score])}  #{count_text}"]
      lines.concat(trait_lines(data[:metrics])) if name == :llm_judge
      lines.concat(issue_lines(data[:issues]))
      lines.concat(rationale_lines(data[:metrics][:rationale])) if name == :llm_judge && data[:metrics][:rationale]
      lines << ''
      lines
    end

    def count_label(name, count)
      return colorize('model-judged, no line-level issues', :dim) if name == :llm_judge
      return colorize('clean', :dim) if count.zero?

      "#{count} issue#{'s' unless count == 1}"
    end

    def trait_lines(metrics)
      pairs = TRAIT_LABELS.filter_map { |key, label| ["#{label}:", metrics[key].to_i] if metrics[key] }
      return [] if pairs.empty?

      pairs.each_slice(2).map { |row| "      #{row.map { |label, score| format('%<label>-14s %<score>-3d', label:, score:) }.join('   ')}" }
    end

    def issue_lines(issues)
      shown = issues.first(ISSUES_SHOWN_PER_ANALYZER)
      lines = shown.map { |issue| "    #{colorize('.', :dim)} #{issue.message}" }
      remaining = issues.size - shown.size
      lines << colorize("    ... (#{remaining} more)", :dim) if remaining.positive?
      lines
    end

    def rationale_lines(rationale)
      wrapped = wrap(rationale, 66)
      ['', colorize("    \"#{wrapped.join("\n     ")}\"", :cyan)]
    end

    def wrap(text, width)
      text.split.each_with_object(['']) do |word, lines|
        candidate = lines.last.empty? ? word : "#{lines.last} #{word}"
        candidate.length > width ? lines << word : lines[-1] = candidate
      end
    end

    def bar(score)
      filled = (score / 100.0 * BAR_WIDTH).round.clamp(0, BAR_WIDTH)
      colorize("#{'#' * filled}#{'-' * (BAR_WIDTH - filled)}", score_color(score))
    end

    def score_color(score)
      return :green if score >= 80
      return :yellow if score >= 60

      :red
    end

    def colorize(text, color_key) = @color ? "#{ANSI[color_key]}#{text}#{ANSI[:reset]}" : text
  end
end
