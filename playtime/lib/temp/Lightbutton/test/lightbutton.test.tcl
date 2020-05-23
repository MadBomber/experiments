#############################
#
# lightbutton v 0.9.1 tests
#
# ulis, 2002
#
#############################

set trace 0

# ---------------------
#
# packages
#
# ---------------------

package require Tk 8.4
lappend auto_path [pwd]
lappend auto_path [file join [pwd] ..]
package require tcltest 2.1
namespace import -force ::tcltest::test
if {$trace} \
{
  package require Flow
  namespace import ::flow::*
  activate:trace
  ignore:procs option:key value:check ::lightbutton::lb:dispatch post:process
  start:trace
}
package require Lightbutton 1.1
namespace import -force ::lightbutton::lightbutton

# ---------------------
#
# init
#
# ---------------------

set fixed {Courier -12}
set data "
  #define v_width 8
  #define v_height 10
  static unsigned char v_bits[] = { 0xff, 0xff, 0x7e, 0x7e, 0x3c, 0x3c, 0x18, 0x18, 0x00, 0x00 };"
image create bitmap _image1_ -data $data
image create bitmap _image2_ -data $data

# ---------------------
#
# class operations
#
# ---------------------

# lightbutton dispatch

test lightbutton-1.1 \
  {lightbutton dispatch} \
  {
    list [catch {lightbutton} msg] $msg
  } \
  {1 {bad operation "": should be <path> or defaults}}

test lightbutton-1.2 \
  {lightbutton dispatch} \
  {
    list [catch {lightbutton boggy} msg] $msg
  } \
  {1 {bad operation "boggy": should be <path> or defaults}}

# defaults

test lightbutton-2.1 \
  {lightbutton defaults} \
  {
    list [catch {lightbutton defaults} msg] $msg
  } \
  {1 {wrong # args: should be "lightbutton defaults $operation $args"}}

test lightbutton-2.2 \
  {lightbutton defaults} \
  {
    list [catch {lightbutton defaults boggy} msg] $msg
  } \
  {1 {bad operation "boggy": should be get or set}}

# defaults get

test lightbutton-3.1 \
  {lightbutton defaults get} \
  {
    list [catch {lightbutton defaults get boggy} msg] $msg
  } \
  {1 {unknown option "boggy"}}

test lightbutton-3.2 \
  {lightbutton defaults get} \
  {
    set poptions {}
    foreach {key value} [lightbutton defaults get] \
    { lappend poptions $key }
    set poptions
  } \
  {-activebackground -activeimage -background -borderwidth -command -compound -contrast -cursor -disabledforeground -fill -font -foreground -granularity -graycoef -height -highlightbackground -highlightcolor -highlightthickness -image -imageheight -imagewidth -lightfactor -padx -pady -relief -state -takefocus -text -textrelief -tristatebackground -tristateimage -type -user -value -variable -width}

# defaults set

test lightbutton-4.1 \
  {lightbutton defaults set} \
  {
    list [catch {lightbutton defaults set boggy} msg] $msg
  } \
  {1 {unknown option "boggy"}}

test lightbutton-4.2 \
  {lightbutton defaults set} \
  {
    set options {}
    foreach {key value} [lightbutton defaults set] \
    { lappend options $key }
    set options
  } \
  {-abg -activebackground -activeimage -aimg -background -bd -bg -borderwidth -cmd -command -compound -contrast -cursor -dfg -disabledforeground -fg -fill -font -foreground -granularity -graycoef -hbd -hbg -height -hfg -highlightbackground -highlightcolor -highlightthickness -iheight -img -image -imageheight -imagewidth -iwidth -lfactor -lightfactor -padx -pady -relief -state -takefocus -tbg -text -textrelief -timg -trelief -tristatebackground -tristateimage -type -user -value -variable -width}

# defaults get/set

test lightbutton-5.1 \
  {lightbutton defaults get/set} \
  {
    set count 0
    foreach key $options \
    {
      set gv [lindex [lightbutton defaults get $key] end]
      set sv [lindex [lightbutton defaults set $key] end]
      incr count [expr {$gv == $sv ? 1 : 0}]
    }
    set count
  } \
  {52}


# ---------------------
#
# options setting
#
# ---------------------

lightbutton .l
pack .l
update

set tests \
{
  {-abg #ff0000 #ff0000 boggy {unknown color name "boggy"}}
  {-activebackground #ff0000 #ff0000 boggy {unknown color name "boggy"}}
  {-activeimage _image1_ _image1_}
  {-activeimage "" ""}
  {-aimg _image2_ _image2_}
  {-background #ff0000 #ff0000 boggy {unknown color name "boggy"}}
  {-bd 4 4 boggy {bad screen distance "boggy"}}
  {-bg #ff0000 #ff0000 boggy {unknown color name "boggy"}}
  {-borderwidth 1.3 1 boggy {bad screen distance "boggy"}}
  {-cmd command command}
  {-command command command}
  {-compound center center boggy {bad side "boggy": should be bottom, center, left, none, right or top}}
  {-contrast 0.5 0.5 boggy {expected numeric but got "boggy"}}
  {-cursor arrow arrow boggy {bad cursor spec "boggy"}}
  {-dfg #110022 #110022 boggy {unknown color name "boggy"}}
  {-disabledforeground #110022 #110022 boggy {unknown color name "boggy"}}
  {-fg #110022 #110022 boggy {unknown color name "boggy"}}
  {-fill true 1 boggy {expected boolean but got "boggy"}}
  {-font {Arial 12} {-family Arial -size 12 -weight normal -slant roman -underline 0 -overstrike 0} {boggy font} {expected integer but got "font"}}
  {-foreground #110022 #110022 boggy {unknown color name "boggy"}}
  {-granularity 2 2 boggy {expected numeric but got "boggy"}}
  {-graycoef 0.75 0.75 boggy {expected numeric but got "boggy"}}
  {-hbd 6 6 boggy {bad screen distance "boggy"}}
  {-hbg #112233 #112233 boggy {unknown color name "boggy"}}
  {-height 30 30 boggy {bad screen distance "boggy"}}
  {-hfg #123456 #123456 boggy {unknown color name "boggy"}}
  {-highlightbackground #112233 #112233 boggy {unknown color name "boggy"}}
  {-highlightcolor #123456 #123456 boggy {unknown color name "boggy"}}
  {-highlightthickness 6 6 boggy {bad screen distance "boggy"}}
  {-iheight 30 30 boggy {bad screen distance "boggy"}}
  {-img _image1_ _image1_ boggy {image "boggy" doesn't exist}}
  {-image _image2_ _image2_ boggy {image "boggy" doesn't exist}}
  {-imageheight 30 30 boggy {bad screen distance "boggy"}}
  {-imagewidth 45 45 boggy {bad screen distance "boggy"}}
  {-iwidth 45 45 boggy {bad screen distance "boggy"}}
  {-lfactor 6 6 boggy {expected numeric but got "boggy"}}
  {-lightfactor 6 6 boggy 1 {expected numeric but got "boggy"}}
  {-padx 0 0 boggy {bad screen distance "boggy"}}
  {-pady 0 0 boggy {bad screen distance "boggy"}}
  {-relief groove groove boggy {bad relief "boggy": must be flat, groove, raised, ridge, solid, or sunken}}
  {-state disabled disabled boggy {bad state "boggy": should be active, disabled, normal or tristate}}
  {-takefocus yes 1 boggy {expected boolean but got "boggy"}}
  {-text "any string" "any string" {} {}}
  {-textrelief raised raised boggy {bad relief "boggy": should be flat, raised or sunken}}
  {-trelief raised raised boggy {bad relief "boggy": should be flat, raised or sunken}}
  {-type check check boggy {bad type "boggy": should be check or radio}}
  {-user "any string" "any string" {} {}}
  {-value "any string" "any string" {} {}}
  {-variable ::variable ::variable {} {}}
  {-width 45 45 boggy {bad screen distance "boggy"}}
} 

set i 1
foreach test $tests \
{
  set name [lindex $test 0]
  set default [lightbutton defaults get $name]
  test lightbutton-10.$i.a $name \
  {
    lightbutton defaults set $name [lindex $test 1]
    list $name [lightbutton defaults get $name]
  } \
  [list $name [lindex $test 2]]
  test lightbutton-10.$i.b $name \
  {
    .l configure $name [lindex $test 1]
    list [lindex [.l configure $name] end] [.l cget $name]
  } \
  [list [lindex $test 2] [lindex $test 2]]
  incr i
  if {[lindex $test 3] != ""} \
  {
    test lightbutton-10.$i.c $name \
    {
      list [catch {lightbutton defaults set $name [lindex $test 3]} msg] $msg
    } \
    [list 1 [lindex $test end]]
  }
  lightbutton defaults set $name $default
  incr i
}

# -contrast             {num;0.0:1.0; 0.5   }
test lightbutton-10.1 \
  {-contrast} \
  {
    list [catch {.l config -contrast -2} msg] $msg
  } \
  {1 {"-2" should be greater or equal to 0.0}}
test lightbutton-10.2 \
  {-contrast} \
  {
    list [catch {.l config -contrast 2} msg] $msg
  } \
  {1 {"2" should be less or equal to 1.0}}

# -granularity          {int;1:10;    1     }
test lightbutton-11.1 \
  {-granularity} \
  {
    list [catch {.l config -granularity -2} msg] $msg
  } \
  {1 {"-2" should be greater or equal to 1}}
test lightbutton-11.2 \
  {-granularity} \
  {
    list [catch {.l config -granularity 20} msg] $msg
  } \
  {1 {"20" should be less or equal to 10}}

# -graycoef             {num;0.0:1.0; 0.5   }
test lightbutton-12.1 \
  {-graycoef} \
  {
    list [catch {.l config -graycoef -2} msg] $msg
  } \
  {1 {"-2" should be greater or equal to 0.0}}
test lightbutton-12.2 \
  {-graycoef} \
  {
    list [catch {.l config -graycoef 2} msg] $msg
  } \
  {1 {"2" should be less or equal to 1.0}}

# -lightfactor          {num;1:;      4     }
test lightbutton-14.1 \
  {-lightfactor} \
  {
    list [catch {.l config -lightfactor -2} msg] $msg
  } \
  {1 {"-2" should be greater or equal to 0}}

# -variable            {opt;variable {}    }
test lightbutton-15.1 \
  {-variable} \
  {
    list [catch {.l config -variable boggy} msg] $msg
  } \
  {1 {variable "boggy" must be global or namespaced}}
test lightbutton-15.2 \
  {-variable} \
  {
    catch {.l config -variable ::var}
  } \
  {0}
test lightbutton-15.3 \
  {-variable} \
  {
    set ::var ""
    catch {.l config -variable var}
  } \
  {0}
test lightbutton-15.4 \
  {-variable} \
  {
    namespace eval ::ns { variable var }
    catch {.l config -variable ::ns::var}
  } \
  {0}


# ---------------------
#
# constructor
#
# ---------------------

test lightbutton-20.1 \
  {lb:create} \
  {
    list [catch {lightbutton} msg] $msg
  } \
  {1 {bad operation "": should be <path> or defaults}}
test lightbutton-20.2 \
  {lb:create} \
  {
    list [catch {lightbutton boggy} msg] $msg
  } \
  {1 {bad operation "boggy": should be <path> or defaults}}
test lightbutton-20.3 \
  {lb:create} \
  {
    catch {destroy .l}
    lightbutton .l
    list [winfo exists .l] [winfo class .l] [info commands .l]
  } \
  {1 Lightbutton .l}
test lightbutton-20.4 \
  {lb:create} \
  {
    catch {destroy .l}
    list [catch {lightbutton .l -boggy boggy} msg] $msg [winfo exists .l] [info commands .l]
  } \
  {1 {unknown option "-boggy"} 0 {}}
test lightbutton-20.5 \
  {lb:create} \
  {
    catch {destroy .l}
    lightbutton .l
  } \
  {.l}

# ---------------------
#
# destructor
#
# ---------------------

catch {destroy .l}
lightbutton .l

test lightbutton-30.1 \
  {lb:dispose} \
  {
    destroy .l
    list [info commands .l] [info commands ::lightbutton::_.l] [array names ::lightbutton .l:*]
  } \
  {{} {} {}}

catch {destroy .l}
lightbutton .l -variable ::var

test lightbutton-30.2 \
  {lb:dispose} \
  {
    destroy .l
    catch { set ::var 0 }
  } \
  {0}

# ---------------------
#
# operations
#
# ---------------------

catch {destroy .l}
lightbutton .l

# dispatch

test lightbutton-40.1 \
  {lb:dispatch} \
  {
    list [catch {.l} msg] $msg
  } \
  {1 {wrong # args: should be ".l $operation $args"}}
  
test lightbutton-40.2 \
  {lb:dispatch} \
  {
    list [catch {.l boggy} msg] $msg
  } \
  {1 {bad operation "boggy": should be activate, cget, configure, deactivate, flash, info, invoke, send, toggle or tristate}}
  
# cget

test lightbutton-50.1 \
  {cget} \
  {
    list [catch {.l cget -boggy} msg] $msg
  } \
  {1 {unknown option "-boggy"}}
test lightbutton-50.2 \
  {cget} \
  {
    set list {}
    foreach {key value} [.l cget] { lappend list $key }
    set list
  } \
  $poptions
  
# configure

test lightbutton-51.1 \
  {configure} \
  {
    list [catch {.l configure -boggy} msg] $msg
  } \
  {1 {unknown option "-boggy"}}
test lightbutton-51.2 \
  {configure} \
  {
    list [catch {.l configure -text text boggy} msg] $msg
  } \
  {1 {wrong # args: should be ".l configure ?$option ?$value?? ?$option $value?..."}}
test lightbutton-51.3 \
  {configure} \
  {
    set list {}
    foreach {key value} [.l config] { lappend list $key }
    set list
  } \
  $options
  
# cget/configure

test lightbutton-52.1 \
  {configure operation} \
  {
    .l configure -borderwidth 4
    list [.l configure -borderwidth] [.l cget -borderwidth]
  } \
  {{pixels 4} 4}
test lightbutton-52.2 \
  {configure operation} \
  {
    .l configure -bd 5
    list [.l configure -bd] [.l cget -bd]
  } \
  {{pixels 5} 5}
test lightbutton-52.3 \
  {configure operation} \
  {
    .l configure -borderwidth 6
    .l configure -bd
    list [.l configure -bd] [.l cget -bd]
  } \
  {{pixels 6} 6}
test lightbutton-52.4 \
  {configure operation} \
  {
    .l configure -bd 7
    list [.l configure -borderwidth] [.l cget -borderwidth]
  } \
  {{pixels 7} 7}

# activate

test lightbutton-60.1 \
  {activate} \
  {
    list [catch {.l activate boggy} msg] $msg
  } \
  {1 {wrong # args: should be ".l activate"}}
test lightbutton-60.2 \
  {activate} \
  {
    .l config -state normal
    .l activate
    .l cget -state
  } \
  {active}
test lightbutton-60.3 \
  {activate} \
  {
    set list {}
    .l config -state active
    .l activate
    lappend list [.l cget -state]
    .l config -state normal
    .l activate
    lappend list [.l cget -state]
    .l config -state tristate
    .l activate
    lappend list [.l cget -state]
    .l config -state disabled
    .l activate
    lappend list [.l cget -state]
  } \
  {active active active disabled}
  
# deactivate

test lightbutton-70.1 \
  {deactivate} \
  {
    list [catch {.l deactivate boggy} msg] $msg
  } \
  {1 {wrong # args: should be ".l deactivate"}}
test lightbutton-70.2 \
  {deactivate} \
  {
    .l config -state active
    .l deactivate
    .l cget -state
  } \
  {normal}
test lightbutton-70.3 \
  {deactivate} \
  {
    set list {}
    .l config -state active
    .l deactivate
    lappend list [.l cget -state]
    .l config -state normal
    .l deactivate
    lappend list [.l cget -state]
    .l config -state tristate
    .l deactivate
    lappend list [.l cget -state]
    .l config -state disabled
    .l deactivate
    lappend list [.l cget -state]
  } \
  {normal normal normal disabled}
  
# toggle

test lightbutton-80.1 \
  {toggle} \
  {
    list [catch {.l toggle boggy} msg] $msg
  } \
  {1 {wrong # args: should be ".l toggle"}}
test lightbutton-80.2 \
  {toggle} \
  {
    set list {}
    .l config -type check -state active
    .l toggle
    lappend list [.l cget -state]
    .l toggle
    lappend list [.l cget -state]
  } \
  {normal active}
test lightbutton-80.3 \
  {toggle} \
  {
    set list {}
    .l config -type check -state normal
    .l toggle
    lappend list [.l cget -state]
    .l toggle
    lappend list [.l cget -state]
  } \
  {active normal}
test lightbutton-80.4 \
  {toggle} \
  {
    set list {}
    .l config -type check -state disabled
    .l toggle
    lappend list [.l cget -state]
    .l toggle
    lappend list [.l cget -state]
  } \
  {disabled disabled}
test lightbutton-80.5 \
  {toggle} \
  {
    set list {}
    .l config -type radio -state active
    .l toggle
    lappend list [.l cget -state]
    .l toggle
    lappend list [.l cget -state]
  } \
  {active active}
test lightbutton-80.6 \
  {toggle} \
  {
    set list {}
    .l config -type radio -state normal
    .l toggle
    lappend list [.l cget -state]
    .l toggle
    lappend list [.l cget -state]
  } \
  {active active}
test lightbutton-80.7 \
  {toggle} \
  {
    set list {}
    .l config -type radio -state disabled
    .l toggle
    lappend list [.l cget -state]
    .l toggle
    lappend list [.l cget -state]
  } \
  {disabled disabled}
  
# tristate

test lightbutton-85.1 \
  {tristate} \
  {
    list [catch {.l tristate boggy} msg] $msg
  } \
  {1 {wrong # args: should be ".l tristate"}}
test lightbutton-85.2 \
  {tristate} \
  {
    .l config -state active
    .l tristate
    .l cget -state
  } \
  {tristate}
test lightbutton-85.3 \
  {tristate} \
  {
    set list {}
    .l config -state active
    .l tristate
    lappend list [.l cget -state]
    .l config -state normal
    .l tristate
    lappend list [.l cget -state]
    .l config -state tristate
    .l tristate
    lappend list [.l cget -state]
    .l config -state disabled
    .l tristate
    lappend list [.l cget -state]
  } \
  {tristate tristate tristate disabled}
  
# info

.l config -aimg _image1_ -img _image2_

test lightbutton-90.1 \
  {info} \
  {
    list [catch {.l info} msg] $msg
  } \
  {1 {wrong # args: should be ".l info $name"}}
test lightbutton-90.2 \
  {invalidate operation} \
  {
    list [catch {.l info boggy} msg] $msg
  } \
  {1 {bad info name "boggy": should be activecolor, activeimage, color, image, tristatecolor or tristateimage}}
test lightbutton-90.3 \
  {info} \
  {
    list [catch {.l info aimg boggy} msg] $msg
  } \
  {1 {wrong # args: should be ".l info $name"}}
test lightbutton-90.4 \
  {info} \
  {
    list [.l info aimg] [.l info img]
  } \
  {_image1_ _image2_}
test lightbutton-90.5 \
  {info} \
  {
    list [.l info activeimage] [.l info image]
  } \
  {_image1_ _image2_}
  
# invoke

catch {destroy .l}
lightbutton .l -command {set ::x command}

test lightbutton-100.1 \
  {info} \
  {
    list [catch {.l invoke boggy} msg] $msg
  } \
  {1 {wrong # args: should be ".l invoke"}}
test lightbutton-100.2 \
  {info} \
  {
    set ::x ""
    .l invoke
    set ::x
  } \
  {command}
  
# send

.l config -command {set ::x send}

test lightbutton-110.1 \
  {send} \
  {
    list [catch {.l send} msg] $msg
  } \
  {1 {wrong # args: should be ".l send $event"}}
test lightbutton-110.2 \
  {send} \
  {
    list [catch {.l send boggy} msg] $msg
  } \
  {1 {unknown event "boggy": should be <Return> or <space>}}
test lightbutton-110.2 \
  {send} \
  {
    set ::x ""
    .l send <space>
    set ::x
  } \
  {send}
  
# set value

.l config -type radio -value value

test lightbutton-120.1 \
  {set_value} \
  {
    .l config -var ::var
    set list {}
    set ::var ""
    lappend list [.l cget -state]
    set ::var ""
    lappend list [.l cget -state]
    set ::var value
    lappend list [.l cget -state]
    set ::var value
    lappend list [.l cget -state]
    set ::var ""
    lappend list [.l cget -state]
  } \
  {normal normal active active normal}

catch { destroy .l }
lightbutton .l -type check -var ::var -value 1

test lightbutton-120.2 \
  {set_value} \
  {
    set list {}
    lappend list [.l cget -state]
    set ::var 1
    lappend list [.l cget -state]
    set ::var 1
    lappend list [.l cget -state]
    set ::var 0
    lappend list [.l cget -state]
    set ::var 0
    lappend list [.l cget -state]
    set ::var 1
    lappend list [.l cget -state]
  } \
  {normal active active normal normal active}

# ---------------------
#
# end of tests
#
# ---------------------

option clear
tcltest::cleanupTests