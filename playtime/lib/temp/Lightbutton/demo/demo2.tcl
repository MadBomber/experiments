# --------------------------------
#
# lightbutton demo 0
#
# various light buttons
#
# --------------------------------

# -----------
# packages
# -----------

  lappend auto_path [pwd]
  lappend auto_path [file join [pwd] ..]
  package require Lightbutton
  namespace import ::lightbutton::*
  
# -----------
# demo
# -----------

  wm title . "various buttons"
  set list \
  {
    1   0.3 crossed
    2   1   rhomb
    3   2   circle
    4   4   rounded
  }
  lightbutton defaults set -font {Arial -10} \
    -iwidth 48 -iheight 48 -state active
  lightbutton defaults set -bg cyan \
    -fill 1 -bd 2
  foreach {n fact name} $list \
  { lightbutton .lb1$n -lfact $fact }
  lightbutton defaults set -bg orange \
    -fill 0 -bd 0 -compound bottom \
    -width 48 -height 78 -pady 10
  foreach {n fact name} $list \
  { lightbutton .lb2$n -lfact $fact -text $name }
  lightbutton .lb3 -fill 1 -text Quit \
    -abg green -bg red -bd 2 \
    -width 48 -height 48 -compound center \
    -command {.lb3 flash; after 1500 exit}
  grid .lb11 .lb12 .lb13 .lb14 -padx 5
  grid .lb21 .lb22 .lb23 .lb24
  grid .lb3 -columnspan 4 -pady 10
