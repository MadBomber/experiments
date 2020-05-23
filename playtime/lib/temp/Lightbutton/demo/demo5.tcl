# --------------------------------
#
# lightbutton demo 5
#
# stars
#
# --------------------------------

  # -------------
  # packages
  # -------------

  lappend auto_path [pwd]
  lappend auto_path [file join [pwd] ..]
  package require Lightbutton
  namespace import ::lightbutton::lightbutton

  # -------------
  # demo
  # -------------

  wm title . stars
  set size 150
  wm geometry . ${size}x$size
  lightbutton default set \
    -takefocus 0 -hbd 0 -lfactor 0.66 \
    -fill 0 -bd 0 -width 9 -height 9 \
    -bg gold -state active
  for {set i 0} {$i < $size / 4} {incr i} \
  {
    set x [expr {int(rand() * $size)}]
    set y [expr {int(rand() * $size)}]
    lightbutton .$i 
    if {rand() < 0.125} { .$i config -bg white }
    if {rand() < 0.005} { .$i config -bg red }
    place .$i -x $x -y $y -anchor center
  }
  proc twinkle {} \
  {
    catch \
    { .[expr {int(rand() * $::size)}] flash }
    after [expr {int(rand() * 500)}] twinkle
  }
  twinkle
