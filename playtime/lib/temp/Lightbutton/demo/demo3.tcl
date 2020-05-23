# --------------------------------
#
# lightbutton demo 0
#
# compound light buttons
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

  wm title . "compound buttons"
  lightbutton defaults set -font {Arial -10} \
    -width 80 -height 80 -state active \
    -iwidth 40 -iheight 40 -bg gold \
    -padx 10 -pady 10 -granularity 2 -lfact 1
  foreach w {left right center top bottom} \
  {
    lightbutton .$w -text $w -compound $w
    pack .$w -padx 80
  }