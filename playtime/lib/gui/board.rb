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
    text            'Dismiss'
    command proc{
      tmppath       = $board_window
      $board_window = nil
      tmppath.destroy
    }
  }.pack( 'side'    => 'left',
          'expand'  => 'yes'
        )

  TkButton.new(frame) {
    text      'Button TWO'
    command   proc{
      puts "Button TWO was clicked"
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
  # TODO: shoot and record hit in label
  debug_me("Cell Clicked") {[ :button_label ]}
  if 1 == rand(2) # hit?
    system 'say hit'
    system('say you sunk my battleship') if 1 == rand(2)
    button.text             = "HIT"
    button.configure(
      'background'          => 'red',
      'foreground'          => 'red',
      'activebackground'    => 'red',
      'activeforeground'    => 'red',
      'highlightbackground' => 'red'
    )
  end

end

