# frozen_string_literal: true

# Ratatui-based terminal renderer for the creature terrarium.
# Renders a 2D grid with colored robot icons, a status bar, and a
# scrolling color-coded lifecycle events panel using ratatui_ruby widgets.
class Renderer
  COLOR_MAP = {
    red:     :red,
    green:   :green,
    yellow:  :yellow,
    blue:    :blue,
    magenta: :magenta,
    cyan:    :cyan,
    white:   :white,
  }.freeze

  # Dimmed background tints for territory display
  TERRITORY_BG = {
    red:     "#2a0000",
    green:   "#002a00",
    yellow:  "#2a2a00",
    blue:    "#00002a",
    magenta: "#2a002a",
    cyan:    "#002a2a",
    white:   "#1a1a1a",
  }.freeze

  def initialize(world, runner = nil)
    @world  = world
    @runner = runner
  end

  def render(tui, tick_rate: nil, command_buffer: nil)
    tui.draw do |frame|
      # Outer vertical split: main area on top, command bar at bottom
      main_area, command_area = tui.layout_split(
        frame.area,
        direction: :vertical,
        constraints: [
          tui.constraint_min(5),
          tui.constraint_length(3),
        ]
      )

      # Horizontal split: left 67% (grid + status), right 33% (lifecycle)
      left_area, lifecycle_area = tui.layout_split(
        main_area,
        direction: :horizontal,
        constraints: [
          tui.constraint_percentage(67),
          tui.constraint_percentage(33),
        ]
      )

      # Vertical sub-split in left area: grid fills remaining, status fixed height
      grid_area, status_area = tui.layout_split(
        left_area,
        direction: :vertical,
        constraints: [
          tui.constraint_min(5),
          tui.constraint_length(5),
        ]
      )

      # Resize world to fill the available grid area (minus borders)
      @world.resize(grid_area.width - 2, grid_area.height - 2)

      frame.render_widget(build_grid(tui), grid_area)
      frame.render_widget(build_status(tui, tick_rate: tick_rate), status_area)
      frame.render_widget(build_lifecycle(tui, lifecycle_area), lifecycle_area)
      frame.render_widget(build_command_bar(tui, command_buffer), command_area)
    end
  end

  private

  def build_grid(tui)
    lines = @world.height.times.map do |y|
      spans = @world.width.times.map do |x|
        robot = @world.cell_at(x, y)
        territory = @world.territory_at(x, y)
        bg = territory ? TERRITORY_BG[territory.owner_color] : nil

        if robot
          fg = COLOR_MAP[robot.creature.color] || :white
          style = bg ? tui.style(fg: fg, bg: bg) : tui.style(fg: fg)
          tui.text_span(content: robot.creature.icon, style: style)
        else
          marker = @world.marker_at(x, y)
          if marker
            fg = COLOR_MAP[marker.color] || :white
            style = bg ? tui.style(fg: fg, bg: bg, modifiers: [:dim]) : tui.style(fg: fg, modifiers: [:dim])
            tui.text_span(content: marker.symbol, style: style)
          elsif territory
            if territory.strength > 0
              label = (territory.strength % 9).to_s
              tui.text_span(content: label, style: tui.style(fg: :dark_gray, bg: bg))
            else
              tui.text_span(content: ".", style: tui.style(fg: :dark_gray, bg: bg))
            end
          else
            tui.text_span(content: " ")
          end
        end
      end
      tui.text_line(spans: spans)
    end

    tui.paragraph(
      text: lines,
      block: tui.block(
        title: "Dynamic Creature Terrarium",
        borders: [:all],
        border_style: tui.style(fg: :cyan),
        border_type: :rounded
      )
    )
  end

  def build_status(tui, tick_rate: nil)
    tui.paragraph(
      text: build_status_lines(tui, tick_rate: tick_rate),
      block: tui.block(
        title: "Status",
        borders: [:all],
        border_style: tui.style(fg: :dark_gray),
        border_type: :rounded
      )
    )
  end

  def build_lifecycle(tui, lifecycle_area)
    visible_lines = lifecycle_area.height - 2 # subtract border lines
    visible_lines = 1 if visible_lines < 1

    log_lines = @world.event_log.last(visible_lines).map do |entry|
      color = lifecycle_event_color(entry)
      tui.text_line(spans: [
        tui.text_span(content: entry, style: tui.style(fg: color))
      ])
    end

    tui.paragraph(
      text: log_lines,
      block: tui.block(
        title: "Lifecycle",
        borders: [:all],
        border_style: tui.style(fg: :yellow),
        border_type: :rounded
      )
    )
  end

  def build_command_bar(tui, command_buffer)
    active = !command_buffer.nil?

    if active
      line = tui.text_line(spans: [
        tui.text_span(content: ": ", style: tui.style(fg: :cyan)),
        tui.text_span(content: command_buffer, style: tui.style(fg: :white)),
        tui.text_span(content: "\u2588", style: tui.style(fg: :cyan)),
      ])
    else
      line = tui.text_line(spans: [
        tui.text_span(
          content: "Press : to command a robot (Name: instruction)",
          style: tui.style(fg: :dark_gray)
        ),
      ])
    end

    border_color = active ? :cyan : :dark_gray

    tui.paragraph(
      text: [line],
      block: tui.block(
        title: "Command",
        borders: [:all],
        border_style: tui.style(fg: border_color),
        border_type: :rounded
      )
    )
  end

  def lifecycle_event_color(entry)
    # Strip the [tN] prefix to inspect the event body
    body = entry.sub(/\A\[t\d+\]\s*/, "")

    case body
    when /\A\+/       then :green
    when /\A-/        then :yellow
    when /\Ax\s/      then :red
    when /\A!!/       then :magenta
    when /\A!/        then :magenta
    when /\A~/        then :cyan
    when /\A\*\*\*/   then :yellow
    when /\A\[/       then :dark_gray
    else                   :dark_gray
    end
  end

  def build_status_lines(tui, tick_rate: nil)
    lines = []

    # Line 1: tick, robot count, speed
    tps = tick_rate ? (1.0 / tick_rate).round(1) : nil
    header = [
      tui.text_span(content: "tick: ", style: tui.style(fg: :dark_gray)),
      tui.text_span(content: @world.tick_count.to_s, style: tui.style(fg: :white)),
      tui.text_span(content: "  robots: ", style: tui.style(fg: :dark_gray)),
      tui.text_span(content: @world.robot_count.to_s, style: tui.style(fg: :white)),
    ]
    if tps
      header << tui.text_span(content: "  speed: ", style: tui.style(fg: :dark_gray))
      header << tui.text_span(content: "#{tps}/s", style: tui.style(fg: :cyan))
      header << tui.text_span(content: " [\u2191\u2193]", style: tui.style(fg: :dark_gray))
    end
    if @runner && @runner.pending_count > 0
      header << tui.text_span(content: "  async: ", style: tui.style(fg: :dark_gray))
      header << tui.text_span(content: @runner.pending_count.to_s, style: tui.style(fg: :yellow))
    end
    lines << tui.text_line(spans: header)

    # Line 2: per-robot territory counts
    robot_spans = []
    summary = @world.territory_summary
    @world.robot_states.each_value do |state|
      fg = COLOR_MAP[state.creature.color] || :white
      count = summary[state.creature.name] || 0
      robot_spans << tui.text_span(content: state.creature.icon, style: tui.style(fg: fg))
      robot_spans << tui.text_span(content: " #{state.creature.name}(#{count})  ", style: tui.style(fg: :white))
    end
    lines << tui.text_line(spans: robot_spans) unless robot_spans.empty?

    lines
  end
end
