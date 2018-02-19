#!/usr/bin/env ruby
# gui/board.rb

# frozen_string_literal: false
#
# Show the board for battleship game
#


# destory to existing toplevel window widget for board
if defined?($board_window) && $board_window
  $board_window.destroy
  $board_window = nil
end

# Create the Board toplevel window widget
$board_window = TkToplevel.new { |window|
  title           "The Ocean of Conflict"
  iconname        "board"
  positionWindow  window
}

base_frame = TkFrame.new($board_window).
  pack( fill:   :both,
        expand: true
      )

# label
msg = TkLabel.new(base_frame) {
  font        $font
  wraplength  '4i'
  justify     'left'
  text        "This is the ocean around your Navy"
}

msg.pack( 'side' => 'top' )


# frame
TkFrame.new(base_frame) { |frame|
  TkButton.new(frame) {
    text            'Show Positions' # 'Dismiss'
    command proc{
      # tmppath       = $board_window
      # $board_window = nil
      # tmppath.destroy
      show_my_positions
    }
  }.pack( 'side'    => 'left',
          'expand'  => 'yes'
        )

  TkButton.new(frame) {
    text      'Prepare to Fight'
    command   proc{
      puts "Button 'Prepare to Fight' was clicked"
      reset_ocean_labels
    }
  }.pack( 'side'    => 'left',
          'expand'  => 'yes'
          )

}.pack( 'side'  => 'bottom',
        'fill'  => 'x',
        'pady'  => '2m'
      )

# frame

# Special trick: select a darker color for the space by creating a
# scrollbar widget and using its trough color.
begin
  if Tk.windowingsystem() == 'aqua'
    frameWidth  = 42 * 10
    frameHeight = 42 * 10
  elsif Tk.default_widget_set == :Ttk
    frameWidth  = 37 * 10
    frameHeight = 31 * 10
  else
    frameWidth  = 30 * 10
    frameHeight = 30 * 10
  end
rescue
  frameWidth  = 30 * 10
  frameHeight = 30 * 10
end


s = TkScrollbar.new(base_frame)

base = TkFrame.new(base_frame) {
  width         frameWidth
  height        frameHeight
  borderwidth   2
  relief        'sunken'
  bg            s['troughcolor']
}


s.destroy

base.pack(  'side'  => 'top',
            'padx'  => '1c',
            'pady'  =>  '1c'
          )

def ocean_clicked_proc(button, cell_id)
  proc{ocean_clicked(button, cell_id)}
end

# SMELL: using a global, really?
#        There are lots of globals in this Tk junk!
$button_position = Hash.new

# create 100 buttons in a 10x10 grid
100.times.each do |button_index|
  button_label        = sprintf "%02i", button_index

  $button_position[button_label] = {
    x: (button_index % 10) * 0.1,
    y: (button_index / 10) * 0.1
  }

  $button_position[button_label][:button] = TkButton.new(base) { |button|
    relief              'raised'
    text                button_label
    highlightthickness  0
    command proc{ ocean_clicked(button, button_label) }
  }.place(
    'relx'      => $button_position[button_label][:x],
    'rely'      => $button_position[button_label][:y],
    'relwidth'  => 0.1,
    'relheight' => 0.1
  )

end # 100.times.each do |button_index|

# User clicked on an ocean square on the board
# button ......... (button widget) the button object
# button_label ... (String) the button number ie. coordinate
def ocean_clicked(button, button_label)

  if deploy_navy?
    debug_me("Cell Clicked") {[ :button_label,
      'convert_map_coordinate(button_label)',
      'configatron.ship_type.value',
      'configatron.ship_orientation.value',
      'configatron.ship_type.symbol',
      'configatron.ship_orientation.symbol' ]}

      begin
        configatron.game.place_ship(
          configatron.player,
          configatron.ship_type.symbol,
          convert_map_coordinate(button_label),
          configatron.ship_orientation.symbol
        )
      rescue => e
        puts e
      end
    show_my_positions
  else
    begin
      result = configatron.game.shoot( configatron.player, convert_map_coordinate(button_label))
    rescue
      result = 'dup'
    end

    system "say #{result}"

    if %w[hit sunk].include? result.to_s
      puts "#{configatron.player}: #{button_label} #{result}"
      button.text             = "HIT"
      button.configure(
        'background'          => 'red',
        'foreground'          => 'red',
        'activebackground'    => 'red',
        'activeforeground'    => 'red',
        'highlightbackground' => 'red'
      )
    end # if %w[hit sunk].include? result.to_s

    if configatron.game.has_winner?
      system "say 'The battle is over.  #{configatron.game.winner_name} has won the battle.'"
    end
  end # if deploy_navy?
end # def ocean_clicked(button, button_label)


def show_my_positions
  board = get_my_board
  char_index = 0
  ('00'..'99').each do |button_name|
    unless ' '==board[char_index]
      $button_position[button_name][:button].text = board[char_index]
    end
    char_index += 1
  end # ('00'..'99').each do |button_name|
end # def show_my_positions


def reset_ocean_labels
  ('00'..'99').each do |button_name|
    $button_position[button_name][:button].text = button_name
  end # ('00'..'99').each do |button_name|
end # def reset_ocean_labels
