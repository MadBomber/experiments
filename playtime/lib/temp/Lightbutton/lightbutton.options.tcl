# ####################################
#
#   lightbutton widget v 0.9.1
#
#   (C) 2003, ulis
#   NOL (no obligation licence)
#
# ------------------------------------
#
# options definition/management
#
# ####################################
  
  # ====================
  #
  # widget options default/action
  #
  # ====================

  foreach {key desc} \
  {
    -abg                  {-activebackground}
    -activebackground     {opt;color            {}    }
    -activeimage          {opt;image            {}    }
    -aimg                 {-activeimage}
    -background           {color                {}    }
    -bd                   {-borderwidth}
    -bg                   {-background}
    -borderwidth          {pixels               {}    }
    -cmd                  {-command}
    -command              {string               {}    }
    -compound             {compound             center}
    -contrast             {num;0.0:1.0;         0.5   }
    -cursor               {cursor               {}    }
    -dfg                  {-disabledforeground}
    -disabledforeground   {color                {}    }
    -fg                   {-foreground}
    -fill                 {boolean              1     }
    -font                 {font                 {}    }
    -foreground           {color                {}    }
    -granularity          {int;1:10;            1     }
    -graycoef             {num;0.0:1.0;         0.5   }
    -hbd                  {-highlightthickness}
    -hbg                  {-highlightbackground}
    -height               {pixels               40    }
    -hfg                  {-highlightcolor}
    -highlightbackground  {color                {}    }
    -highlightcolor       {color                {}    }
    -highlightthickness   {pixels               {}    }
    -iheight              {-imageheight}
    -img                  {-image}
    -image                {opt;image            {}    }
    -imageheight          {pixels               0     }
    -imagewidth           {pixels               0     }
    -iwidth               {-imagewidth}
    -lfactor              {-lightfactor}
    -lightfactor          {nz;pos;              4     }
    -padx                 {pixels               0     }
    -pady                 {pixels               0     }
    -relief               {relief               ridge }
    -state                {state                normal}
    -takefocus            {opt;boolean          {}    }
    -tbg                  {-tristatebackground}
    -text                 {string               {}    }
    -textrelief           {trelief              flat  }
    -timg                 {-tristateimage}
    -trelief              {-textrelief}
    -tristatebackground   {opt;color            {}    }
    -tristateimage        {opt;image            {}    }
    -type                 {type                 check }
    -user                 {string               {}    }
    -value                {string               {}    }
    -variable             {opt;variable         {}    }
    -width                {pixels               40    }
  } \
  { 
    set (:defs:default:$key) $desc
    lappend (:defs:names) $key 
  }
  set (_w) ._lightbutton_test_
  button $(_w)
  foreach key \
  {
    -background
    -borderwidth
    -disabledforeground
    -font
    -foreground
    -highlightbackground 
    -highlightcolor     
    -highlightthickness
    -takefocus
  } \
  { lset (:defs:default:$key) 1 [$(_w) cget $key] }

  foreach {key flags script} \
  {
    -activebackground     {fi fs}             {}
    -activeimage          {fi fs fc fr}       {}
    -background           {fi fs}             {}
    -borderwidth          {}                  { %f% config %key% %value% }
    -compound             {fc fr}             {}
    -contrast             {fi fs}             {}
    -cursor               {}                  { 
                                                %f% config %key% "%value%" 
                                                %c% config %key% "%value%" 
                                              }
    -disabledforeground   {}                  { %c% itemconfig text1 -disabledfill "%value%" }
    -font                 {}                  { %c% itemconfig text %key% "%value%" }
    -fill                 {fi fs}             {}
    -foreground           {}                  { %c% itemconfig text1 -fill "%value%" }
    -graycoef             {fi fs}             {}
    -height               {fi fs fc fr}       {}
    -highlightbackground  {}                  { %f% config %key% "%value%" }
    -highlightcolor       {}                  { %f% config %key% "%value%" }
    -highlightthickness   {}                  { %f% config %key% %value% }
    -image                {fi fs fc fr}       {}
    -imageheight          {fi fs fc fr}       {}
    -imagewidth           {fi fs fc fr}       {}
    -lightfactor          {fi fs}             {}
    -padx                 {fi fs fc fr}       {}
    -pady                 {fi fs fc fr}       {}
    -relief               {}                  { %f% config %key% %value% }
    -state                {fs}                { set (%w%:_state) "%old%" }
    -takefocus            {}                  { %f% config %key% %value% }
    -text                 {}                  { %c% itemconfig text %key% "%value%" }
    -textrelief           {fr}                {}
    -tristatebackground   {fi fs}             {}
    -tristateimage        {fi fs fc fr}       {}
    -value                {fv}                {}
    -variable             {fv}                { set (%w%:_variable) "%old%" }
    -width                {fi fs fc fr}       {}
    -granularity          {fi fs fc fr}       {}
  } \
  { 
    set (:defs:flags:$key) $flags 
    set (:defs:script:$key) $script 
  }
  set (:defs:flags) {fi fs fc fr fv}
  set (:defs:script:BEGIN)  {}
  set (:defs:script:END)    {}
  
  destroy $(_w)
  array unset {} _*  

  # ====================
  #
  # general procs
  #
  # ====================

  # --------------------
  # option:key
  # --
  # get an option descriptor key
  # --------------------
  # parm1: partial key of the option
  # --------------------
  # return: the option descriptor key
  # --------------------
  proc option:key {key} \
  {
    variable {}
    # search the key
    if {[set n [lsearch -glob $(:defs:names) $key*]] == -1} \
    { error "unknown option \"$key\"" }
    set key [lindex $(:defs:names) $n]
    set desc $(:defs:default:$key)
    if {[llength $desc] == 1} { set key [lindex $desc 0] }
    return $key
  }
  
  # --------------------
  # value:check
  # --
  # check & normalize an option value
  # --------------------
  # parm1: type of the option 
  # parm2: new value for the option
  # --------------------
  # return: normalized value
  # --------------------
  proc value:check {type value} \
  {
    variable {}
    set int 0
    set num 0
    set opt 0
    set nz 0
    set types [split $type \;]
    set type [lindex $types end]
    foreach pfx [lrange $types 0 end-1] \
    {
      switch -exact $pfx \
      {
        int     { set int 1 }
        num     { set num 1 }
        nz      { set nz 1; set num 1 }
        opt     { set opt 1 }
        pos     { set min 0; set num 1 }
        default \
        { 
          foreach {min max} [split $pfx :] break 
          set num 1
        }
      }
    }
    if {$opt && $value == ""} { return "" }
    set oldvalue $value
    if {$num} \
    {
      if {![string is double -strict $value]} \
      { error "expected numeric but got \"$oldvalue\"" }
    }
    if {$int} \
    {
      if {![string is integer -strict $value]} \
      { error "expected integer but got \"$oldvalue\"" }
    }
    if {$type == "pixels"}  \
    { set value [winfo pixels . $value] }
    if {[info exists min] && $min != "" && $value < $min} \
    { error "\"$oldvalue\" should be greater or equal to $min" }
    if {[info exists max] && $max != "" && $value > $max} \
    { error "\"$oldvalue\" should be less or equal to $max" }
    if {$nz && abs($value) < 1.e-6} \
    { error "bad value \"$oldvalue\": must be non zero" }
    switch -exact -- $type \
    {
      boolean   \
      { 
        if {![string is boolean -strict $value]} \
        { error "expected boolean but got \"$value\"" }
        set  value [expr {$value ? 1 : 0}]
      }
      color     { winfo rgb . $value }
      compound  \
      {
        switch -glob -- $value \
        {
          bot*    { set value bottom }
          cen*    { set value center }
          lef*    { set value left }
          non*    { set value none }
          rig*    { set value right }
          top     { set value top }
          default \
          { error "bad side \"$value\": should be bottom, center, left, none, right or top" }
        }
      }
      cursor    \
      { 
        set current [. cget -cursor]
        . config -cursor $value
        . config -cursor $current
      }
      font      { set value [font actual $value] }
      image     { image width $value }
      relief    \
      { 
        set relief [. cget -relief]
        . config -relief $value
        . config -relief $relief
      }
      state     \
      {
        switch -glob -- $value \
        {
          act*    { set value active }
          dis*    { set value disabled }
          nor*    { set value normal }
          tri*    { set value tristate }
          default \
          { error "bad state \"$value\": should be active, disabled, normal or tristate" }
        }
      }
      trelief   \
      {
        switch -glob -- $value \
        {
          fla*    { set value flat }
          rai*    { set value raised }
          sun*    { set value sunken }
          default \
          { error "bad relief \"$value\": should be flat, raised or sunken" }
        }
      }
      type      \
      {
        switch -glob -- $value \
        {
          che*    { set value check }
          rad*    { set value radio }
          default \
          { error "bad type \"$value\": should be check or radio" }
        }
      }
      variable  \
      {
        if {![string match ::* $value]} \
        {
          set v [uplevel 1 namespace which -variable $value]
          if {$v == ""} \
          { error "variable \"$value\" must be global or namespaced" }
          set value $v
        }
      }
    }
    return $value
  }
  
  # ====================
  #
  # default values procs
  #
  # ====================

  # --------------------
  # default:get
  # --
  # get options default value
  # --------------------
  # parm1: options list or option or empty
  # --------------------
  # return: 
  #   if options list, default values list
  #   if option, default value
  #   if empty, keys followed by corresponding default value list
  # --------------------
  proc default:get {args} \
  {
    variable {}
    switch [llength $args] \
    {
      0       \
      { 
        # all options
        foreach key $(:defs:names) \
        { 
          # get descriptor
          set desc $(:defs:default:$key)
          # exclude synonyms
          if {[llength $desc] > 1} \
          {
            # append key & default value
            lappend res $key [lindex $desc end]
          }
        }
        return $res
      } 
      1       \
      {
        # one option
        set key [lindex $args 0]
          # get descriptor
        set desc $(:defs:default:[option:key $key])
          # return default value
        return [lindex $desc end]
      }
      default \
      {
        # selected options
        foreach key $args \
        { 
          # get descriptor
          set desc $(:defs:default:[option:key $key])
          # append default value
          lappend res [lindex $desc end]
        }
        return $res
      }
    }
  }

  # --------------------
  # default:set
  # --
  # set options default value
  # --------------------
  # parm1: list of key/value pairs or key or empty
  # --------------------
  # return: 
  #   if key/values pairs list, nothing
  #   if key, corresponding descriptor
  #   if empty, keys followed by corresponding descriptor list
  # --------------------
  proc default:set {args} \
  {
    variable {}
    switch [llength $args] \
    {
      0   \
      { 
        # all options
        foreach key $(:defs:names) \
        { 
          # append key & descriptor
          lappend res $key $(:defs:default:$key) 
        }
        return $res
      }
      1   \
      { 
        # one option, return descriptor
        set key [lindex $args 0]
        return $(:defs:default:[option:key $key])
      }
      default \
      {
        # key/value pairs
        foreach {key value} $args \
        { 
          switch -glob -- $key \
          {
            +ref*   \
            {
            }
            default \
            {
              # get descriptor key
              set key [option:key $key]
              # check & normalize value
              set type [lindex $(:defs:default:$key) 0]
              set value [value:check $type $value]
              # update default value
              lset (:defs:default:$key) end $value 
            }
          }
        }
      }
    }
  }

  # ====================
  #
  # current values procs
  #
  # ====================

  # --------------------
  # current:get
  # --
  # get options current value
  # --------------------
  # parm1: widget reference
  # parm2: options list or option or empty
  # --------------------
  # return: 
  #   if options list, current values list
  #   if option, current value
  #   if empty, keys followed by corresponding current value list
  # --------------------
  proc current:get {w args} \
  {
    variable {}
    switch [llength $args] \
    {
      0       \
      { 
        # all options
        foreach key $(:defs:names) \
        { 
          # get descriptor
          set desc $(:defs:default:$key)
          # exclude synonyms
          if {[llength $desc] > 1} \
          {
            # append key & current value
            lappend res $key $($w:$key)
          }
        }
        return $res
      } 
      1       \
      {
        # one option, return current value
        set key [lindex $args 0]
        return $($w:[option:key $key])
      }
      default \
      {
        # selected options
        foreach key $args \
        { 
          # append default value
          lappend res $($w:[option:key $key])
        }
        return $res
      }
    }
  }

  # --------------------
  # current:set
  # --
  # set options current value
  # --------------------
  # parm1: widget reference
  # parm2: list of key/value pairs or key or empty
  # --------------------
  # return: 
  #   if key/values pairs list, nothing
  #   if key, corresponding descriptor
  #   if empty, keys followed by corresponding descriptor list
  # --------------------
  proc current:set {w args} \
  {
    variable {}
    switch [llength $args] \
    {
      0   \
      { 
        # all options
        foreach key $(:defs:names) \
        { 
          # get descriptor
          set desc $(:defs:default:$key)
          if {[llength $desc] != 1} \
          {
            # create an updated descriptor
            set desc [lreplace $(:defs:default:$key) end end $($w:$key)]
          }
          # append key & descriptor
          lappend res $key $desc
        }
        return $res
      }
      1   \
      { 
        # one option, return descriptor
        set key [option:key [lindex $args 0]]
        return [lreplace $(:defs:default:$key) end end $($w:$key)]
      }
      default \
      {
        # preprocess
        foreach f $(:defs:flags) { set ($w:flag:$f) 0 }
        set _map [list %w% $w %f% _$w %c% $w.c]
        eval [string map $_map $(:defs:script:BEGIN)]
        # key/value pairs
        foreach {key value} $args \
        {
          # update current value
          set key [option:key $key]
          set old $($w:$key)
          set type [lindex $(:defs:default:$key) 0]
          set value [value:check $type $value]
          set ($w:$key) $value
          if {[info exists (:defs:script:$key)]} \
          {
            foreach f $(:defs:flags:$key) { incr ($w:flag:$f) }
            set script $(:defs:script:$key)
            if {$script != ""} \
            {
              set map $_map
              lappend map %key% $key %value% $value %old% $old
              eval [string map $map $script]
            }
          }
        }
        # postprocess
        eval [string map $_map $(:defs:script:END)]
        foreach f $(:defs:flags) \
        { if {$($w:flag:$f) > 0} { post:process $w $f } }
      }
    }
  }
