#!/usr/bin/env ruby
# gui/board.rb

# frozen_string_literal: false
# puzzle.rb
#
# This demonstration script creates a 15-puzzle game using a collection
# of buttons.
#
# widget demo 'puzzle' (called by 'widget')
#

# toplevel widget
if defined?($puzzle_demo) && $puzzle_demo
  $puzzle_demo.destroy
  $puzzle_demo = nil
end

# demo toplevel widget
$puzzle_demo = TkToplevel.new { |w|
  title           "The Ocean of Conflict"
  iconname        "15-Puzzle"
  positionWindow  w
}

base_frame = TkFrame.new($puzzle_demo).
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
      tmppath       = $puzzle_demo
      $puzzle_demo  = nil
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

def ocean_clicked_proc(w, num)
  proc{ocean_clicked(w, num)}
end

# SMELL: using a global, really?
$button_position = Hash.new

# create 100 buttons in a 10x10 grid
100.times.each do |button_index|
  button_label        = sprintf "%02i", button_index

  $button_position[button_label] = {
    x: (button_index % 10) * 0.1,
    y: (button_index / 10) * 0.1
  }

  TkButton.new(base) { |w|
    relief              'raised'
    text                button_label
    highlightthickness  0
    command ocean_clicked_proc(w, button_label)
  }.place(  'relx'      => $button_position[button_label][:x], # $xpos[button_label],
            'rely'      => $button_position[button_label][:y], # $ypos[button_label],
            'relwidth'  => 0.1,
            'relheight' => 0.1
          )
end # 100.times.each do |button_index|

# User clicked on an ocean square on the board
# w .............. (widget) the button object
# button_label ... (String) the button number ie. coordinate
def ocean_clicked(w, button_label)
  puts "Clicked on #{button_label}"
end

