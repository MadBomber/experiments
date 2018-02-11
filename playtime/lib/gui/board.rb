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
$puzzle_demo = TkToplevel.new {|w|
  title("The Ocean of Conflict")
  iconname("15-Puzzle")
  positionWindow(w)
}

base_frame = TkFrame.new($puzzle_demo).pack(:fill=>:both, :expand=>true)

# label
msg = TkLabel.new(base_frame) {
  font $font
  wraplength '4i'
  justify 'left'
  text "This is the ocean around your Navy"
}

msg.pack('side'=>'top')

# frame
TkFrame.new(base_frame) {|frame|
  TkButton.new(frame) {
    text 'Dismiss'
    command proc{
      tmppath = $puzzle_demo
      $puzzle_demo = nil
      tmppath.destroy
    }
  }.pack('side'=>'left', 'expand'=>'yes')

  TkButton.new(frame) {
    text 'Show Code'
    command proc{showCode 'puzzle'}
  }.pack('side'=>'left', 'expand'=>'yes')

}.pack('side'=>'bottom', 'fill'=>'x', 'pady'=>'2m')

# frame

# Special trick: select a darker color for the space by creating a
# scrollbar widget and using its trough color.
begin
  if Tk.windowingsystem() == 'aqua'
    frameWidth  = 168 / 4 * 10
    frameHeight = 168 / 4 * 10
  elsif Tk.default_widget_set == :Ttk
    frameWidth  = 148 / 4 * 10
    frameHeight = 124 / 4 * 10
  else
    frameWidth  = 120 / 4 * 10
    frameHeight = 120 / 4 * 10
  end
rescue
  frameWidth  = 120 / 4 * 10
  frameHeight = 120 / 4 * 10
end


s = TkScrollbar.new(base_frame)

base = TkFrame.new(base_frame) {
  width  frameWidth
  height frameHeight
  borderwidth 2
  relief 'sunken'
  bg s['troughcolor']
}

s.destroy

base.pack('side'=>'top', 'padx'=>'1c', 'pady'=>'1c')

def ocean_clicked_proc(w, num)
  proc{ocean_clicked(w, num)}
end

# SMELL: really silly way to store a coordinate
$xpos = {}
$ypos = {}

# create 100 buttons in a 10x10 grid
100.times.each do |i|
  num = i
  $xpos[num] = (i % 10) * 0.1
  $ypos[num] = (i / 10) * 0.1
  TkButton.new(base) {|w|
    relief 'raised'
    text num
    highlightthickness 0
    command ocean_clicked_proc(w, num)
  }.place(  'relx'=>$xpos[num],
            'rely'=>$ypos[num],
            'relwidth'=>0.1,
            'relheight'=>0.1
          )
end

# User clicked on an ocean square on the board
# w ..... (widget) the button object
# num ... (integer) the button number ie. coordinate
def ocean_clicked(w, num)
  puts "Clicked on #{num}"
end

