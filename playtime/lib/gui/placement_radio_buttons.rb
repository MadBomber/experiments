#!/usr/bin/env ruby
# gui/placement_radio_buttons.rb
# Let user select the the ship and its orientation.
#
# frozen_string_literal: false
#
# Creates a toplevel window containing radio
# button widgets for ship selection and orientation.
#

# QUESTION?  Tk is old fashion using strings for some option hashes
#            and sometimes I see symboles used for the same method.
#            I'm wondering what would happen if I converted everything
#            to symbols and used the modern syntax ...


# toplevel window widget
if defined?($placement_window) && $placement_window
  $placement_window.destroy
  $placement_window = nil
end

# toplevel window widget
$placement_window = TkToplevel.new {|window|
  title           "Place Your Navy"
  iconname        "placement"
  positionWindow  window
}

base_frame = TkFrame.new(
  $placement_window
).pack(
  fill:     :both,
  expand:   :true
)

# label
msg = TkLabel.new(base_frame) {
  font        $font
  wraplength  '5i'
  justify     'left'
  text        "Place your Navy on the Ocean"
}

msg.pack(
  'side'  => 'top'
)

#
configatron.ship_type         = TkVariable.new
configatron.ship_orientation  = TkVariable.new

# bottom frame to hold the buttons
TkFrame.new(base_frame) { |frame|

  # Close Button
  TkButton.new(frame) {
    text    'Close'
    command proc{
      tmppath                     = $placement_window
      $placement_window           = nil
      $showVarsWin[tmppath.path]  = nil
      tmppath.destroy
    }
  }.pack(
      'side'    => 'left',
      'expand'  => 'yes'
    )

  # see_variables_button
  TkButton.new(frame) {
    text    'See Variables'
    command proc{
      showVars( base_frame,
                 ['ship_type',        configatron.ship_type],
                 ['ship_orientation', configatron.ship_orientation]
              )
    }
  }.pack(
    'side'    => 'left',
    'expand'  => 'yes'
  )
}.pack(
  'side'  => 'bottom',
  'fill'  => 'x',
  'pady'  => '2m'
)

# frame for the ship type selection
type_frame  = TkLabelFrame.new(
  base_frame,
  'text'      => 'Ship Type',
  'pady'      => 2,
  'padx'      => 2
).pack(
  'side'    => 'left',
  'expand'  => 'yes',
  'padx'    => '.5c',
  'pady'    => '.5c'
)

# frame for the ship orientation selection
orientation_frame   = TkLabelFrame.new(
  base_frame,
  'text'      =>'Orientation',
  'pady'      => 2,
  'padx'      => 2
).pack(
  'side'    => 'left',
  'expand'  => 'yes',
  'padx'    => '.5c',
  'pady'    =>'.5c'
)


# Define the radio button set for ship type
[
  :aircraft_carrier,
  :battleship,
  :cruiser,
  :destroyer,
  :submarine
].each do |type|
  TkRadioButton.new(type_frame) {
    text      type.to_s.titleize
    variable  configatron.ship_type
    relief    'flat'
    value     type
  }.pack(
      'side'    => 'top',
      'pady'    => 2,
      'anchor'  =>'w',
      'fill'    => 'x'
  )
end


# Define the radio button set for ship orientation
[
  :horizontally,
  :vertically
].each do |orientation|
  TkRadioButton.new(orientation_frame) {
    text      orientation.to_s.titleize
    variable  configatron.ship_orientation
    relief    'flat'
    value     orientation
    anchor    'w'
  }.pack(
      'side'  => 'top',
      'pady'  => 2,
      'fill'  => 'x'
  )
end

