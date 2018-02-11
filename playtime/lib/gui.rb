#!/usr/bin/env ruby
# -wU
# lib/gui.rb
#
# Assumes that Tcl/Tk is version 8.5 or greater.

require 'awesome_print'
require 'debug_me'
include DebugMe

require 'tk'

### $DEBUG=1 ##########


#----------------------------------------------------------------
# The code below create the main window, consisting of a menu bar
# and a text widget that explains how to use the program.
#----------------------------------------------------------------

# root
$root = TkRoot.new{
  title "Battleships GUY Using Ruby/Tk"
}

# tk
$tk_version = Tk::TK_VERSION
$tk_major_ver, $tk_minor_ver = $tk_version.split('.').map{|n| n.to_i}
$tk_patchlevel = Tk::TK_PATCHLEVEL


# tcl_platform
$tk_platform = TkVarAccess.new('tcl_platform')

debug_me{[ '$tk_version', '$tk_major_ver', '$tk_minor_ver', '$tk_patchlevel', '$tk_platform' ]}


# Set the default font
$font = TkFont.new('Helvetica -12')

# Add a menubar to the root window
$root.add_menubar(
  [[
    ['File',        0],
    ['About ... ',  proc{aboutBox}, 0, '<F1>'],
    '---',
    ['Quit',        proc{exit}, 0, 'Ctrl-Q']
  ]]
)


$root.bind('F1',        proc{aboutBox})
$root.bind('Control-q', proc{exit})


# Create the application window (aka frame) on the root (aka desktop) window
textFrame = TkFrame.new($root)

scr = TkScrollbar.new(
        $root,
        'orient'              => 'vertical',
        'highlightthickness'  => 0,
        'takefocus'           => 1
      ) {
          pack(
            'in'    => textFrame,
            'side'  => 'right',
            'fill'  => 'y',
            'padx'  => 1
          )
        }

txt = TkText.new($root) {
  wrap                'word'
  width               70
  height              30
  font                $font
  setgrid             'yes'
  highlightthickness  0
  padx                4
  pady                2
  takefocus           0
  bd                  1
  yscrollcommand      proc{ |first,last| scr.set first, last }
}

scr.command( proc{ |*args| txt.yview(*args) } )


textFrame.pack(
  'expand'  => 'yes',
  'fill'    => 'both'
)

#  $root.withdraw.deiconify

Tk.update_idletasks

txt.pack(
  'in'      => textFrame,
  'expand'  => 'yes',
  'fill'    => 'both'
)

statusBar = TkFrame.new($root) { |f|
  statusfont      = 'Helvetica 10'
  $statusBarLabel = TkLabel.new(
    f,
    'text'    => "   ",
    'relief'  => 'sunken',
    'bd'      => 1,
    'anchor'  => 'w',
    'font'    => statusfont
  ).pack(
      'side'    => 'left',
      'padx'    => 2,
      'expand'  => 'yes',
      'fill'    => 'both'
  )

  TkLabel.new(
    f,
    'width'   => 8,
    'relief'  => 'sunken',
    'bd'      => 1,
    'anchor'  => 'w',
    'font'    => statusfont
  ).pack(
      'side'  => 'left',
      'padx'  => 2
    )
}.pack(
    'side'  => 'bottom',
    'fill'  => 'x',
    'pady'  => 2
)


tag_title = TkTextTag.new(
  txt,
  'font'  => 'Helvetica 18 bold'
)

# SMELL: Not required for the Battleship GUI ??
# We put some "space" characters around each demo description
# so that the descriptions are highlighted only when the mouse cursor
# is right over them (but not when the cursor is to their left or right)

tag_demospace = TkTextTag.new(
  txt,
  'lmargin1'  => '1c',
  'lmargin2'  => '1c'
)


tag_demo = TkTextTag.new(
  txt,
  'lmargin1'    => '1c',
  'lmargin2'    => '1c',
  'foreground'  => 'blue',
  'underline'   => 1
)


$tag_visited = TkTextTag.new(
  txt,
  'lmargin1'    => '1c',
  'lmargin2'    => '1c',
  'foreground'  => '#303080',
  'underline'   => 1
)


#  tag_hot = TkTextTag.new(txt, 'relief'=>'raised', 'borderwidth'=>1,
#                         'background'=>'SeaGreen3')

tag_hot = TkTextTag.new(
  txt,
  'borderwidth' => 1,
  'foreground'  => 'red'
)


tag_demo.bind(
  'ButtonRelease-1',
  proc{ |x,y|
    invoke(
      txt,
      txt.index(
        "@#{x},#{y}"
      )
    )
  },
  '%x %y'
)

lastLine = TkVariable.new("")
newLine  = TkVariable.new("")

tag_demo.bind(
  'Enter',
  proc{ |x,y|
        lastLine.value = txt.index("@#{x},#{y} linestart")
        tag_hot.add(lastLine.value, "#{lastLine.value} lineend")
        showStatus(txt, txt.index("@#{x},#{y}"))
  },
  '%x %y'
)


tag_demo.bind(
  'Leave',
  proc{
    tag_hot.remove('1.0','end')
    txt.configure('cursor','xterm')
    $statusBarLabel.configure('text'=>"")
  }
)


tag_demo.bind(
  'Motion',
  proc{ |x, y|
    newLine.value = txt.index("@#{x},#{y} linestart")

    if newLine.value != lastLine.value
      tag_hot.remove('1.0', 'end')
      lastLine.value = newLine.value
      if (
            txt.tag_names("@#{x},#{y}").find{ |t|
              t.kind_of?(String) && t =~ /^demo-/
            }
         )
        tag_hot.add(
          lastLine.value,
          "#{lastLine.value} lineend -1 chars"
        )
      end
    end # if newLine.value != lastLine.value

    showStatus(txt, txt.index("@#{x},#{y}"))
  },
  '%x %y'
)


# Create the text for the text widget.

txt.insert(
  'end',
  "GUI for Battleships using Ruby/Tk\n\n",
  tag_title
)

txt.insert(
  'end',
  <<~EOT
    This application provides a notional GUI front end for the game of battleship.  It is not a complete game, just enough to show some of the capabilities of the Ruby tecnology that is not often seem by many Ruby/Rails web-developers.

    Does your Tk support Ttk (Tile) extension (included or installed) ? ( Probably, Ttk extension #{
    begin
      require 'tkextlib/tile'
      "is already installed on your environment."
    rescue
      "is not installed on your environment yet."
    end
    } )

    Ttk extension is a standard feature of Tk8.5 or later.

  EOT
)


txt.state('disabled')
scr.focus


# positionWindow --
# This procedure is invoked to position a new window.
#
# Arguments:
# window - The window object to position.

def positionWindow(window)
  window.geometry('+300+300')
end


# showVars --
# Displays the values of one or more variables in a window, and
# updates the display whenever any of the variables changes.
#
# Arguments:
# w -           Name of new window to create for display.
# args -        Any number of names of variables.

$showVarsWin = Hash.new



def showVars(parent, *args)
  if $showVarsWin[parent.path]
    begin
      $showVarsWin[parent.path].destroy
    rescue
    end
  end
  $showVarsWin[parent.path] = TkToplevel.new(parent) {|top|
    title "Variable values"

    base = TkFrame.new(top).pack(:fill=>:both, :expand=>true)

    TkLabelFrame.new(base, :text=>"Variable values:",
                     :font=>{:family=>'Helvetica', :size=>14}){|f|
      args.each{|vnam,vbody|
        TkGrid(TkLabel.new(f, :text=>"#{vnam}: ", :anchor=>'w'),
               TkLabel.new(f, :textvariable=>vbody, :anchor=>'w'),
               :padx=>2, :pady=>2, :sticky=>'w')
      }

      f.grid(:sticky=>'news', :padx=>4)
      f.grid_columnconfig(1, :weight=>1)
      f.grid_rowconfig(100, :weight=>1)
    }
    TkButton.new(base, :text=>"OK", :width=>8, :default=>:active,
                 :command=>proc{top.destroy}){|b|
      top.bind('Return', proc{b.invoke})
      top.bind('Escape', proc{b.invoke})

      b.grid(:sticky=>'e', :padx=>4, :pady=>[6, 4])
    }
    base.grid_columnconfig(0, :weight=>1)
    base.grid_rowconfig(0, :weight=>1)
  }
end # def showVars(parent, *args)




# Pseudo-Toplevel support
module PseudoToplevel_Evaluable
  def pseudo_toplevel_eval(body = Proc.new)
    Thread.current[:TOPLEVEL] = self
    begin
      body.call
    ensure
      Thread.current[:TOPLEVEL] = nil
    end
  end # def pseudo_toplevel_eval(body = Proc.new)


  def pseudo_toplevel_evaluable?
    @pseudo_toplevel_evaluable
  end # def pseudo_toplevel_evaluable?


  def pseudo_toplevel_evaluable=(mode)
    @pseudo_toplevel_evaluable = (mode)? true: false
  end # def pseudo_toplevel_evaluable=(mode)

  def self.extended(mod)
    mod.__send__(:extend_object, mod)
    mod.instance_variable_set('@pseudo_toplevel_evaluable', true)
  end # def self.extended(mod)
end # module PseudoToplevel_Evaluable


class Object
  alias __method_missing__ method_missing
  private :__method_missing__

  def method_missing(id, *args)
    begin
      has_top = (top = Thread.current[:TOPLEVEL]) &&
                   top.respond_to?(:pseudo_toplevel_evaluable?) &&
                   top.pseudo_toplevel_evaluable? &&
                   top.respond_to?(id)
    rescue Exception => e
      has_top = false
    end

    if has_top
      top.__send__(id, *args)
    else
      __method_missing__(id, *args)
    end
  end
end # class Object


class Proc
  def initialize(*args)
    super
    @__pseudo_toplevel__ = Thread.current[:TOPLEVEL]
  end

  alias __call__ call
  def call(*args, &b)
    if top = @__pseudo_toplevel__
      orig_top = Thread.current[:TOPLEVEL]
      Thread.current[:TOPLEVEL] = top
      begin
        __call__(*args, &b)
      ensure
        Thread.current[:TOPLEVEL] = orig_top
      end
    else
      __call__(*args, &b)
    end
  end
end # class Proc


def proc(&block)
  Proc.new(&block)
end


def lambda(&block)
  Proc.new(&block)
end


def _null_binding
  Module.new.instance_eval{extend PseudoToplevel_Evaluable}
  # binding
  # Module.new.instance_eval{binding}
end
private :_null_binding



# showStatus --
#
#       Show the name of the demo program in the status bar. This procedure
#       is called when the user moves the cursor over a demo description.
#

def showStatus (txt, index)
  tag = txt.tag_names(index).find{|t| t.kind_of?(String) && t =~ /^demo-/}
  cursor = txt.cget('cursor')
  unless tag
    $statusBarLabel.configure('text', " ")
    newcursor = 'xterm'
  else
    demoname = tag[5..-1]
    $statusBarLabel.configure('text',
                             "Run the \"#{demoname}\" sample program")
    newcursor = 'hand2'
  end
  txt.configure('cursor'=>newcursor) if cursor != newcursor
end # def showStatus (txt, index)




# aboutBox
#
#      Pops up a message box with an "about" message
#
def aboutBox
  Tk.messageBox(
    'icon'    => 'info',
    'type'    => 'ok',
    'title'   => 'About Widget Demo',
    'message' => <<~MESSAGE
      Playing with the Ruby/Tk gem with a battleships game.

      The Ruby/TK library API is very unRuby-ish.

      Using ActiveSlate's ActiveTk on MacOSX High Serria.

      Ruby & Tk Version ::
      Ruby#{RUBY_VERSION}(#{RUBY_RELEASE_DATE})[#{RUBY_PLATFORM}] / Tk#{$tk_patchlevel}#{(Tk::JAPANIZED_TK)? '-jp': ''}
      Ruby/Tk release date :: tcltklib #{TclTkLib::RELEASE_DATE}; tk #{Tk::RELEASE_DATE}
    MESSAGE
  )
end # def aboutBox



#########################################
# load the Battleship game GUI windows

require 'active_support/inflector' # NOTE: only using titleize
require 'require_all'
require_all "./gui/*.rb"




#########################################
# start eventloop

Tk.mainloop

