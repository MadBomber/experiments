#!/usr/bin/env ruby
# gui/placement_radio_buttons.rb
# Let user select the orientation.

require 'active_support/inflector'

# frozen_string_literal: false
# radio2.rb
#
# This demonstration script creates a toplevel window containing
# several radiobutton widgets.
#
# radiobutton widget demo (called by 'widget')
#

# toplevel widget
if defined?($radio2_demo) && $radio2_demo
  $radio2_demo.destroy
  $radio2_demo = nil
end

# demo toplevel widget
$radio2_demo = TkToplevel.new {|w|
  title("Radiobutton Demonstration 2")
  iconname("radio2")
  positionWindow(w)
}

base_frame = TkFrame.new($radio2_demo).pack(:fill=>:both, :expand=>true)

# label
msg = TkLabel.new(base_frame) {
  font $font
  wraplength '5i'
  justify 'left'
  text "Place your Navy on the Ocean"
}
msg.pack('side'=>'top')

#
size = TkVariable.new
color = TkVariable.new
align = TkVariable.new

# frame
TkFrame.new(base_frame) {|frame|
  TkButton.new(frame) {
    text 'Dismiss'
    command proc{
      tmppath = $radio2_demo
      $radio2_demo = nil
      $showVarsWin[tmppath.path] = nil
      tmppath.destroy
    }
  }.pack('side'=>'left', 'expand'=>'yes')

  TkButton.new(frame) {
    text 'Show Code'
    command proc{showCode 'radio2'}
  }.pack('side'=>'left', 'expand'=>'yes')

  TkButton.new(frame) {
    text 'See Variables'
    command proc{
      showVars(base_frame,
               ['size', size], ['color', color], ['compound', align])
    }
  }.pack('side'=>'left', 'expand'=>'yes')
}.pack('side'=>'bottom', 'fill'=>'x', 'pady'=>'2m')

# frame
f_left  = TkLabelFrame.new(base_frame, 'text'=>'Ship Type',
                           'pady'=>2, 'padx'=>2)
f_mid   = TkLabelFrame.new(base_frame, 'text'=>'Orientation',
                           'pady'=>2, 'padx'=>2)
f_right = TkLabelFrame.new(base_frame, 'text'=>'Alignment',
                           'pady'=>2, 'padx'=>2)
f_left.pack('side'=>'left', 'expand'=>'yes', 'padx'=>'.5c', 'pady'=>'.5c')
f_mid.pack('side'=>'left', 'expand'=>'yes', 'padx'=>'.5c', 'pady'=>'.5c')
f_right.pack('side'=>'left', 'expand'=>'yes', 'padx'=>'.5c', 'pady'=>'.5c')

# radiobutton
[
  :aircraft_carrier,
  :battleship,
  :cruiser,
  :destroyer,
  :submarine
].each {|ship_type|
  TkRadioButton.new(f_left) {
    text ship_type.to_s.titleize
    variable size
    relief 'flat'
    value ship_type
  }.pack('side'=>'top', 'pady'=>2, 'anchor'=>'w', 'fill'=>'x')
}

[
  :horizontal,
  :vertical
].each {|orientation|
  TkRadioButton.new(f_mid) {
    text orientation.to_s.titleize
    variable color
    relief 'flat'
    value orientation
    anchor 'w'
  }.pack('side'=>'top', 'pady'=>2, 'fill'=>'x')
}

