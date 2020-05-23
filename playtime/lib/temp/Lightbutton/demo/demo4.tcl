# --------------------------------
#
# lightbutton demo 4
#
# fires
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

  wm title . lights
  lightbutton default set \
    -takefocus 0 -hbd 0 -lfactor 2 \
    -fill 0 -bd 0
  # create the control
  lightbutton .control -type check -hbd 0 -pady 6 \
      -compound bottom -text on/off -font {Arial -10} \
      -iwidth 8 -iheight 8 -bg red -abg green -height 30
  # create the three fires
  frame .f -bd 2 -relief solid -bg gray35
  lightbutton default set \
    -iwidth 32 -iheight 32 -width 37 -height 37 \
    -var ::lights -lfactor 2 -fill 0 -bd 0 -type radio
  foreach color {red orange green} \
  { 
    lightbutton .f.$color -value $color -background $color
    bind .f.$color <ButtonPress-1> [list click .f.$color]
  }
  # create the feed back
  label .l -width 6 -textvariable ::lights
  # create the mechanism
    # the main switch
  bind .control <<LightbuttonChange>> \
  {
    if {[.control cget -state] == "active"} \
    { 
      .f.orange config -type check
      foreach fire {green orange red} \
      { .f.$fire config -state normal }
      blink 
      set ::lights blink 
    } \
    else \
    { 
      catch {after cancel $::blink} 
      foreach fire {green orange red} \
      { .f.$fire config -state disabled }
      set ::lights off 
    }
  }
    # the secondary switches
  proc click {w} \
  {
    #catch { flow -start commands }
    if {[.control cget -state] != "active"} \
    { return }
    catch {after cancel $::blink} 
    .f.orange config -type radio
    $w activate
    set ::lights $::lights
  }
    # the blink
  proc blink {} \
  {
    .f.orange toggle
    set ::blink [after 1000 blink]
  }
  
  # display the widgets
  pack .control .f .l -pady 5
  pack .f.red .f.orange .f.green
  # activate
  .control activate
  focus -force .control
