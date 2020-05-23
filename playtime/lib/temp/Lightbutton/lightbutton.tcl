if {[info exists ::lightbutton::version]} { return }
namespace eval ::lightbutton \
{
# beginning of ::lightbutton namespace definition

# ####################################
#
#   lightbutton widget
#
variable version 1.1
#
#   ulis, (C) 2003
#
# ------------------------------------
#
#   main script
#
# ------------------------------------
# v 0.10.1, 2004-01-08
#
#   empty name array access
#
# ####################################
  
  # ====================
  #
  # entry point
  #
  # ====================

    namespace export lightbutton
    interp alias {} ::lightbutton::lightbutton \
                 {} ::lightbutton::lb:dispatch lb 

  # ====================
  #
  #   global variables
  #
  # ====================
  
  variable {}
  set (dir) [file dirname [info script]]
  set (:rec:change) 0

  # ==========================
  #
  # package
  #
  # ==========================
  
  package provide LightButton $version
  package provide Lightbutton $version
  package provide lightbutton $version

  package require Tcl 8.4
  package require Tk 8.4

  # ====================
  #
  # operations management
  #
  # ====================

  source [file join $(dir) lightbutton.operations.tcl]
  
  # ====================
  #
  # options management
  #
  # ====================

  source [file join $(dir) lightbutton.options.tcl]

  # ====================
  #
  # class binding
  #
  # ====================

  bind Lightbutton <space> {::lightbutton::lb:toggle %W}

  # ====================
  #
  # create/destroy widget
  #
  # ====================

    # --------------------
    # widget constructor
    # --
    # create a lightbutton
    # --------------------
    # parm1: widget reference
    # parm2: optional option/value pairs list
    # --------------------
    # return: widget reference
    # --------------------
    proc lb:create {w args} \
    {
      variable {}
      # init widget options & variables
      set ($w:init) 1
      set options {}
      foreach key $(:defs:names) \
      { 
        set desc $(:defs:default:$key)
        if {[llength $desc] > 1} \
        {
          set value [lindex $desc end]
          set ($w:$key) $value
          if {$value != ""} { lappend options $key $value }
        }
      }
      set ($w:_variable) ""
      # create subwidgets
      frame $w -class Lightbutton
      canvas $w.c -bd 0 -relief flat -highlightt 0 -insertwidth 0
      $w.c create image 0 0 -anchor center -tags {image move}
      $w.c create text  0 0 -anchor center -tags {text text0 rtext move} -fill gray85
      $w.c create text  0 0 -anchor center -tags {text text2 rtext move} -fill gray25
      $w.c create text  0 0 -anchor center -tags {text text1 move}
      # place the subwidgets
      pack $w.c
      # bindings
      bind $w.c <Destroy> [list ::lightbutton::lb:dispose $w]
      $w.c bind all <ButtonPress-1> [list ::lightbutton::lb:toggle $w]
      bindtags $w.c [list $w $w.c Lightbutton . all]
      # create the widget reference
      rename $w ::lightbutton::_$w
      interp alias {} ::$w {} ::lightbutton::lb:dispatch2 $w
      # update the options
      set:variable $w ::lightbutton::variable
      if {$options != ""} { set args [concat $options $args] }
      if {[catch \
        { uplevel 1 [linsert $args 0 ::lightbutton::current:set $w] } \
          msg]} \
      { 
        destroy $w
        error $msg
      } \
      else \
      { if {$($w:-value) == ""} { set ($w:-value) $w } }
      set ($w:init) 0
      # return reference
      return $w
    }

    # --------------------
    # widget destructor
    # --
    # release all ressources
    # --------------------
    # parm1: widget reference
    # --------------------
    proc lb:dispose {w} \
    {
      variable {}
      # delete images
      set sign \
      $($w:-height):$($w:-width):$($w:-granularity):$($w:-lightfactor):$($w:-fill)
      foreach state {active normal tristate} \
      {
        if {[info exists ($w:color:$state)] 
         && [set color $($w:color:$state)] != ""} \
        {
          if {[incr (:count:$color:$sign) -1] == 0} \
          { image delete $(:images:$color:$sign) } 
        }
      }
      # delete variable trace
      if {$($w:-variable) != ""} \
      { trace remove variable $($w:-variable) {write} [namespace code [list value:change $w]] }
      # delete reference
      catch { rename ::$w "" }
      # free array names
      array unset {} $w:*
    }
  
  # ====================
  #
  # options
  #
  # ====================

    # --------------------
    # post:process
    # --
    # postprocess the new options
    # --------------------
    # parm1: widget reference
    # parm2: subprocess phase
    # --------------------
    proc post:process {w phase} \
    {
      variable {}
      switch $phase \
      {
        fi      \
        {
          # image
          set activecolor $($w:-activebackground)
          set tristatecolor $($w:-tristatebackground)
          set normalcolor $($w:-background)
          if {$activecolor == ""} \
          {
            set activecolor $normalcolor
            set normalcolor [gray:color $w $activecolor]
          }
          if {$tristatecolor == ""} \
          {
            set tristatecolor gray50
          }
          set activeimage $($w:-activeimage)
          if {$activeimage == ""} \
          {
            set ($w:color:active) $activecolor
            set ($w:image:active) [create:gradient $w $activecolor]
          } \
          else \
          { 
            set ($w:color:active) ""
            set ($w:image:active) $activeimage 
          }
          set tristateimage $($w:-tristateimage)
          if {$tristateimage == ""} \
          {
            set ($w:color:tristate) $tristatecolor
            set ($w:image:tristate) [create:gradient $w $tristatecolor]
          } \
          else \
          { 
            set ($w:color:tristate) ""
            set ($w:image:tristate) $tristateimage 
          }
          set normalimage $($w:-image)
          if {$normalimage == ""} \
          {
            set ($w:color:normal) $normalcolor
            set ($w:image:normal) [create:gradient $w $normalcolor]
          } \
          else \
          { 
            set ($w:color:normal) ""
            set ($w:image:normal) $normalimage 
          }
        }
        fc      \
        {
          # compound
          lb:compound $w
        }
        fs      \
        {
          # state
          set state $($w:-state)
          if {$state == "disabled"} \
          { 
            $w.c itemconfig text1 -fill $($w:-disabledforeground)
            $w.c itemconfig image -image $($w:image:normal) 
            $w.c config -state disabled
          } \
          else \
          {
            $w.c itemconfig text1 -fill $($w:-foreground)
            $w.c itemconfig image -image $($w:image:$state)
            $w.c config -state normal
          }
          update
        }
        fr      \
        {
          # text relief
          set trelief $($w:-textrelief)
          if {$trelief != "flat"} \
          {
            $w.c itemconfig text0 -state hidden
            $w.c itemconfig text2 -state normal
            set d [expr {$trelief == "raised" ? -1 : +1}] 
            $w.c move text0 $d $d
            set d [expr {$d * -1}] 
            $w.c move text2 $d $d
          } \
          else \
          { $w.c itemconfig rtext -state hidden }
        }
        fv      \
        {
          # variable
          set:variable $w $($w:-variable)
        }
      }
    }
  
  # ====================
  #
  # info
  #
  # ====================

    # --------------------
    # lb:info
    # --
    # return info from the widget
    # --------------------
    # parm1: path of the widget
    # parm2: info name
    # --------------------
    proc lb:info {w name} \
    {
      variable {}
      switch -glob -- $name \
      {
        aco*        -
        activec*    { set ($w:color:active) }
        aim*        -
        activei*    { set ($w:image:active) }
        col*        { set ($w:color:normal) }
        img         -
        ima*        { set ($w:image:normal) }
        tco*        -
        tristatec*  { set ($w:color:tristate) }
        tim*        -
        tristatei*  { set ($w:image:tristate) }
        default   \
        { error "bad info name \"$name\": should be activecolor, activeimage, color, image, tristatecolor or tristateimage" }
      }
    }

  # ====================
  #
  # state
  #
  # ====================

    # --------------------
    # change:state
    # --
    # change the state of the widget
    # --------------------
    # parm1: path of the widget
    # parm2: optional active flag
    # --------------------
    proc change:state {w {aflag ""}} \
    {
      variable {}
      incr (:rec:change)
      set state $($w:-state)
      set type $($w:-type)
      #if {$aflag == "" && $state == "disabled"} { return }
      if {$aflag != ""} \
      { set newstate [expr {$aflag ? "active" : "normal"}] } \
      elseif {$type == "radio" && $state == "active"} \
      { set newstate active } \
      else \
      { set newstate [expr {$state == "normal" ? "active" : "normal"}] }
      current:set $w -state $newstate
      if {$newstate == "active" && $type == "radio"} \
      { set $($w:-variable) $($w:-value) }
      if {($(:rec:change) == 1 && $newstate == "active") || $type == "check"} \
      { lb:invoke $w }
      incr (:rec:change) -1
    }

    # --------------------
    # lb:toggle
    # --
    # toggle the state of the widget
    # --------------------
    # parm1: path of the widget
    # parm2: optional active flag
    # --------------------
    proc lb:toggle {w {aflag ""}} \
    {
      variable {}
      if {$($w:-state) == "disabled"} { return }
      if {$($w:-borderwidth)} \
      { 
        $w.c move move 1 1
        after 150 $w.c move move -1 -1
        after 160 set ::lightbutton::($w:vwait) 1
        vwait ::lightbutton::($w:vwait)
      }
      change:state $w $aflag
      update
    }

    # --------------------
    # lb:tristate
    # --
    # set the state of the widget to tristate
    # --------------------
    # parm1: path of the widget
    # --------------------
    proc lb:tristate {w} \
    {
      variable {}
      if {$($w:-state) == "disabled"} { return }
      current:set $w -state tristate
      update
    }

    # --------------------
    # lb:activate
    # --
    # activate the widget
    # --------------------
    # parm1: path of the widget
    # --------------------
    proc lb:activate {w} { lb:toggle $w 1 }

    # --------------------
    # lb:deactivate
    # --
    # deactivate the widget
    # --------------------
    # parm1: path of the widget
    # --------------------
    proc lb:deactivate {w} { lb:toggle $w 0 }

    # --------------------
    # lb:flash
    # --
    # flash the widget
    # --------------------
    # parm1: path of the widget
    # --------------------
    proc lb:flash {w} \
    {
      variable {}
      set image [$w.c itemcget image -image]
      set activeimage $($w:image:active)
      set normalimage $($w:image:normal)
      $w.c itemconfig image -image $activeimage ; update
      after 100 $w.c itemconfig image -image $normalimage
      after 110 update
      after 200 $w.c itemconfig image -image $activeimage
      after 210 update
      after 300 $w.c itemconfig image -image $image
      after 310 set ::lightbutton::($w:vwait) 1
      vwait ::lightbutton::($w:vwait)
    }

  # ====================
  #
  # command
  #
  # ====================

    # --------------------
    # lb:invoke
    # --
    # invoke the widget command
    # --------------------
    # parm1: path of the widget
    # --------------------
    proc lb:invoke {w} \
    {
      variable {}
      set cmd $($w:-command)
      if {$cmd != ""} { eval [string map [list %widget% $w] $cmd] }
      event generate $w <<LightbuttonChange>>
    }

  # ====================
  #
  # event
  #
  # ====================

    # --------------------
    # lb:send
    # --
    # send an event to the widget
    # --------------------
    # parm1: path of the widget
    # parm2: event
    # --------------------
    proc lb:send {w event} \
    {
      variable {}
      switch -exact -- $event \
      {
        <Return>  -
        <space>   { ::lightbutton::lb:toggle $w }
        default   \
        { error "unknown event \"$event\": should be <Return> or <space>" }
      }
    }

  # ====================
  #
  # variable/value
  #
  # ====================

    # --------------------
    # set:variable
    # --
    # set the variable
    # --------------------
    # parm1: path of the widget
    # parm2: new variable
    # --------------------
    proc set:variable {w variable} \
    {
      variable {}
      set old $($w:_variable)
      if {$old != $variable} \
      {
        if {$old != ""} \
        { trace remove variable $old {write} [namespace code [list value:change $w]] }
        if {$variable == ""} { set variable ::lightbutton::variable }
        if {![info exists $variable]} { set $variable "" }
        trace add variable $variable {write} [namespace code [list value:change $w]]
        set ($w:-variable) $variable
      }
      if {!$($w:init)} { value:change $w }
    }

    # -------------
    # value:change
    # -
    # called on value change
    # -------------
    # parm1: widget path
    # parm2: trace args
    # -------------
    proc value:change {w args} \
    {
      variable {}
      if {$($w:-state) == "disabled"} { return }
      set value [set $($w:-variable)]
      change:state $w [expr {$value == $($w:-value)}]
    }
  
  # ====================
  #
  # images
  #
  # ====================

    # -------------
    # create:gradient
    # -
    # create a gradient image
    # -------------
    # parm1: widget path
    # parm2: color
    # -------------
    # return: image name
    # -------------
    proc create:gradient {w color} \
    {
      variable {}
      # check the cache
      set iheight $($w:-imageheight)
      if {$iheight == 0} \
      {
        if {[set iheight $($w:-height)] == 0} \
        { error "unable to compute height of the generated image" }
      }
      set iwidth $($w:-imagewidth)
      if {$iwidth == 0} \
      {
        if {[set iwidth $($w:-width)] == 0} \
        { error "unable to compute width of the generated image" }
      }
      set factor $($w:-lightfactor)
      set fill $($w:-fill)
      set granularity $($w:-granularity)
      set sign $color:$iheight:$iwidth:$granularity:$factor:$fill
      if {![info exists (:images:$sign)]} \
      {
        # generate a new image
        set maxc [expr {255 * $($w:-contrast)}]
        set offset [expr {255 - $maxc}]
        foreach {rr gg bb} [winfo rgb . $color] break
        set r [expr {$rr / 65535.0}]
        set g [expr {$gg / 65535.0}]
        set b [expr {$bb / 65535.0}]
        set Dx [expr {($iwidth + $granularity - 1) / $granularity}]
        set Rx [expr {$Dx / 2}]
        set Rx1 [expr {$Rx - 1.e-7}]
        set Dy [expr {($iheight + $granularity - 1) / $granularity}]
        set Ry [expr {$Dy / 2}]
        set Ry1 [expr {$Ry - 1.e-7}]
        set data {}
        # create image
        catch { image delete $image }
        set image [image create photo]
        # compute pixels
        set count 0
        for {set X -$Rx} {$X <= +$Rx} {incr X} \
        {
          set xx2 [expr {pow(abs($X)/double($Rx1),$factor)}]
          set column {}
          set y0 [expr {$fill ? -$Ry : "@"}]
          set y1 @; set yy0 @; set yy1 @; set v0 @; set v1 @
          for {set Y -$Ry} {$Y <= +$Ry} {incr Y} \
          {
            # compute v = |x/a|^n+|y/b|^n (<= 1.0)
            # where a = width/2, b = height/2, n = form factor
            set yy2 [expr {pow(abs($Y)/double($Ry1),$factor)}]
            set v [expr {$xx2 + $yy2}]
            if {!$fill} \
            {
              if {$y0 == "@" && $v < 1.0} { set y0 $Y; set yy0 $yy2; set v0 $v }
              if {$y0 != "@" && $v > 1.0} { set y1 $Y; set yy1 $yy2; set v1 $v; break }
            }
            # compute c = 255 * [(1 - L) + L * (1 - v)]
            # where L is a contrast/luminosity factor
            set c [expr {round($offset + $maxc * (1.0 - $v))}]
            # compute gross pixel
            if {$c < 0} { set c 0 }
            set pixel [format "#%02x" [expr {int($c * $r)}]]
            append pixel [format "%02x" [expr {int($c * $g)}]]
            append pixel [format "%02x" [expr {int($c * $b)}]]
            if {$fill || $y0 != "@"} \
            {
              for {set i 1} {$i <= $granularity} {incr i} \
              { lappend column $pixel }
            }
          }
          if {$column != ""} \
          {
            set X0 [expr {($X + $Rx) * $granularity - 1}]
            set Y0 [expr {($y0 + $Ry) * $granularity}]
            for {set i 0} {$i < $granularity} {incr i} \
            { $image put $column -to [incr X0] $Y0 }
          }
          if {[incr count] == 20} { set count 0; update }
        }
        # cache image
        set (:images:$sign) $image
        set (:count:$sign) 0
      }
      # increment reference count
      incr (:count:$sign)
      return $(:images:$sign)
    }
  
    # -------------
    # gray:color
    # -
    # create a gray color
    # -------------
    # parm1: widget path
    # parm2: color
    # -------------
    # return: new color
    # -------------
    proc gray:color {w color} \
    {
      variable {}
      set coef $($w:-graycoef)
      set coef2 [expr { (1.0 - $coef) / 2.0}]
      foreach {(r) (g) (b)} [winfo rgb . $color] break
      # c' = (1 - L) + L * c
      # where L is a contrast/luminosity factor
      foreach c {r g b} { set ($c) [expr {int($coef2 + $($c) / 256.0 * $coef)}] }
      foreach c {r g b} { append newcolor [format %02x $($c)] }
      return #$newcolor
    }

  # ====================
  #
  # placement
  #
  # ====================

    # -------------
    # lb:compound
    # -
    # place subwidgets
    # -------------
    # parm1: widget path
    # -------------
    proc lb:compound {w} \
    {
      variable {}
      set width $($w:-width)
      set height $($w:-height)
      set iwidth $($w:-imagewidth)
      set iheight $($w:-imageheight)
      set padx $($w:-padx)
      set pady $($w:-pady)
      set font $($w:-font)
      set text $($w:-text)
      set wt [font measure $font $text]
      set ht [font metrics $font -linespace]
      set wi [image width $($w:image:active)]
      set w2 [image width $($w:image:normal)]
      if {$w2 > $wi} { set wi $w2 }
      if {$iwidth > $wi} { set wi $iwidth }
      set hi [image height $($w:image:active)]
      set h2 [image height $($w:image:normal)]
      if {$h2 > $hi} { set hi $h2 }
      if {$iheight > $hi} { set hi $iheight }
      if {$iwidth == 0} { set iwidth $wi }
      if {$iheight == 0} { set iheight $hi }
      # compute sizes
      switch $($w:-compound) \
      {
        none    -
        center  -
        top     -
        bottom  \
        {
          if {$width == 0} \
          { 
            set width [expr {$wt > $iwidth ? $wt : $iwidth}]
          }
          if {$height == 0} \
          { 
            set height [expr {$iheight + $ht + 2 * $pady}]
          }
        }
        right   -
        left    \
        {
          if {$width == 0} \
          { 
            set width [expr {$iwidth + $wt + 2 * $padx}]
          }
          if {$height == 0} \
          { 
            set height [expr {$ht > $iheight ? $ht : $hi}]
          }
        }
      }
      set ($w:width) $width
      set ($w:height) $height
      $w.c config -width $width -height $height
      # compute coordinates
      switch $($w:-compound) \
      {
        bottom  \
        {
          set xi [expr {$width / 2}]
          set yi [expr {$height - $pady}]
          set xt [expr {$width / 2}]
          set yt [expr {$height - $iheight - 2 * $pady}]
          if {$yt < $ht + 2} { set yt [expr {$ht + 2}] }
          $w.c itemconfig all -anchor s
        }
        center  -
        none    \
        {
          set xi [expr {$width / 2}]
          set yi [expr {$height / 2}]
          set xt [expr {$width / 2}]
          set yt [expr {$height / 2}]
          $w.c itemconfig all -anchor center
        }
        left    \
        {
          set xi $padx
          set yi [expr {$height / 2}]
          set xt [expr {$iwidth + 2 * $padx}]
          if {$xt > $width - $wt - 2} { set xt [expr {$width - $wt - 2}] }
          set yt [expr {$height / 2}]
          $w.c itemconfig all -anchor w
        }
        right   \
        {
          set xi [expr {$width - $padx}]
          set yi [expr {$height / 2}]
          set xt [expr {$width - $iwidth - 2 * $padx}]
          if {$xt < $wt + 2} { set xt [expr {$wt + 2}] }
          set yt [expr {$height / 2}]
          $w.c itemconfig all -anchor e
        }
        top     \
        {
          set xi [expr {$width / 2}]
          set yi $pady
          set xt [expr {$width / 2}]
          set yt [expr {$iheight + 2 * $pady}]
          if {$yt > $height - $ht - 2} { set yt [expr {$height - $ht - 2}] }
          $w.c itemconfig all -anchor n
        }
      }
      $w.c coords image $xi $yi
      foreach id [$w.c find withtag text] \
      { $w.c coords $id $xt $yt }
    }

# end of ::lightbutton namespace definition
}
