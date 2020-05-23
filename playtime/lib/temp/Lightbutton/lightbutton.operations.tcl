# ####################################
#
#   lightbutton widget v 0.9.1
#   
#   (C) 2003, ulis
#   NOL (no obligation licence)
#
# ------------------------------------
#
# operations definition/management
#
# ####################################

  # ====================
  #
  # operations descriptions
  #
  # ====================

    # -------------
    #  lightbutton operations description
    #
    #  "lightbutton $operation ?$args?"
    # -------------

    set (:lb:msg) {<path> or defaults}
    set (:lb:map) {list %len% [llength $args]}
    set (:lb:cmd) \
    { 
      .*      \
      {
        {lb:create %operation%}
        {"lightbutton $pathName ?$option $value?..."}
        {%len% % 2 != 0}
      }
      def*    \
      {
        lb:dispatch:defs
        {"lightbutton defaults $operation $args"}
        {%len% < 1}
      }
    }

    interp alias {} ::lightbutton::lb:dispatch:defs {} ::lightbutton::lb:dispatch defs 

    # -------------
    #  lightbutton defaults operations description
    #
    #  "lightbutton defaults $operation ?$args?"
    # -------------

    set (:defs:msg) {get or set}
    set (:defs:map) {list %len% [llength $args]}
    set (:defs:cmd) \
    { 
      get*    \
      {
        default:get
        {"lightbutton defaults get ?$option?..."}
        {0}
      }
      set*    \
      {
        default:set
        {"lightbutton defaults set ?$option ?$value?? ?$option $value?..."}
        {%len% != 1 && %len% % 2 != 0}
      }
    }

    # -------------
    #  path operations description
    #
    #  "<path> $operation ?$args?"
    # -------------

    set (:w:msg) {activate, cget, configure, deactivate, flash, info, invoke, send, toggle or tristate}
    set (:w:map) {list %len% [llength $args] %w% [lindex $args 0]}
    set (:w:cmd) \
    { 
      act*    \
      {
        lb:activate
        {"%w% activate"}
        {%len% != 1}
      }
      cge*    \
      {
        current:get
        {"%w% cget ?$option?..."}
        {0}
      }
      con*    \
      {
        current:set
        {"%w% configure ?$option ?$value?? ?$option $value?..."}
        {%len% != 2 && %len% % 2 != 1}
      }
      dea*    \
      {
        lb:deactivate
        {"%w% deactivate"}
        {%len% != 1}
      }
      fla*    \
      {
        lb:flash
        {"%w% flash"}
        {%len% != 1}
      }
      inf*    \
      {
        lb:info
        {"%w% info $name"}
        {%len% != 2}
      }
      inv*    \
      {
        lb:invoke
        {"%w% invoke"}
        {%len% != 1}
      }
      sen*    \
      {
        lb:send
        {"%w% send $event"}
        {%len% != 2}
      }
      tog*    \
      {
        lb:toggle
        {"%w% toggle"}
        {%len% != 1}
      }
      tri*    \
      {
        lb:tristate
        {"%w% tristate"}
        {%len% != 1}
      }
    }

  # ====================
  #
  # operation/error management
  #
  # ====================

    # ----------------
    # internal generalized dispatch proc
    # ----------------
    # parm1: group name/current operation/optional current operation args list
    # ----------------
    # return: operation result 
    # ----------------
    proc lb:dispatch {args} \
    {
      variable {}
      # check args
      set group [lindex $args 0]
      set operation [lindex $args 1]
      if {[llength $args] < 2} \
      { error "bad operation \"$operation\": should be $(:$group:msg)" }
      set args [lrange $args 2 end]
      # catch error
      set rc [catch \
      {
        # retrieve command
        foreach {pattern item} $(:$group:cmd) \
        { 
          if {[string match $pattern $operation]} \
          { 
            set oper [lindex $item 0]
            set msg [lindex $item 1]
            set conds [lrange $item 2 end]
            break
          } 
        }
        if {![info exists oper]} \
        { error "bad operation \"$operation\": should be $(:$group:msg)" }
        # check args
        set map [eval $(:$group:map)]
        lappend map %operation% $operation
        foreach cond $conds \
        {
          set cond [string map $map $cond]
          if $cond \
          { error "wrong # args: should be [string map $map $msg]" } 
        }
        # eval command
        set oper [string map $map $oper]
        if {[llength $args] == 0} { uplevel 1 ::lightbutton::$oper } \
        else { uplevel 1 ::lightbutton::$oper $args }
      } msg]
      # return result
      if {$rc} \
      { # error
        return -code error $msg
      } \
      else \
      { # ok
        return $msg
      }
    }

    # ----------------
    # internal path dispatch proc
    # ----------------
    # parm1: widget path/current operation/optional current operation args list
    # ----------------
    # return: operation result 
    # ----------------
    proc lb:dispatch2 {args} \
    {
      variable {}
      # check args
      if {[llength $args] < 2} \
      { error "wrong # args: should be \".l \$operation \$args\"" }
      set w [lindex $args 0]
      set operation [lindex $args 1]
      set args [lrange $args 2 end]
      if {[llength $args] == 0} { uplevel 1 ::lightbutton::lb:dispatch w $operation $w } \
      else { uplevel 1 [linsert $args 0 ::lightbutton::lb:dispatch w $operation $w] }
    }
