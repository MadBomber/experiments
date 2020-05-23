# --------------------------------
#
# lightbutton demo 0
#
# simple light button
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

  wm title . "Lightbutton"
  lightbutton .lb -text light -bg green3 -abg red1 -hbd 0
  pack .lb -padx 75
  focus -force .lb
  after 500 .lb send <space>
  vwait forever
