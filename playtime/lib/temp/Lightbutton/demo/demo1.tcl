# --------------------------------
#
# lightbutton demo 1
#
# check & radio light buttons
#
# --------------------------------

# -----------
# packages
# -----------

  lappend auto_path [pwd]
  lappend auto_path [file join [pwd] ..]
  package require Lightbutton
  namespace import -force ::lightbutton::lightbutton
  
# -----------
# demo
# -----------

  wm title . "light buttons"
  lightbutton defaults set -width 36 -height 36 \
    -font {Arial -10} -hbd 0 -relief ridge \
    -granularity 2 -tbg tan
  lightbutton defaults set -bg gold -fg gold \
    -text check -textrelief raised -type check
  foreach w {.lb01  .lb02  .lb03   .lb04   .lb05} \
      state {active active normal tristate active} \
  { lightbutton $w -state $state -var ::$w }
  lightbutton defaults set -bg gray95 -fg gray95 \
    -text radio -textrelief sunken -type radio
  foreach w {.lb11  .lb12  .lb13  .lb14  .lb15} \
      state {normal normal active normal normal} \
  { lightbutton $w -state $state }
  lightbutton .lb23 -bg green -bg red -fg black \
    -text On/Off -type check -textrelief flat \
    -var ::var -command \
  {.lb23 flash; .lb23 config -type radio; after 1000 exit}
  grid .lb01 .lb02 .lb03 .lb04 .lb05
  grid .lb11 .lb12 .lb13 .lb14 .lb15
  grid   x     x   .lb23   x     x   -pady 5
  .lb23 flash
  after 15000 .lb23 invoke
