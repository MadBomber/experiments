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

$RubyTk_WidgetDemo = true

#----------------------------------------------------------------
# The code below create the main window, consisting of a menu bar
# and a text widget that explains how to use the program, plus lists
# all of the demos as hypertext items.
#----------------------------------------------------------------

# widget demo directory
# $demo_dir = File.dirname($0)
$demo_dir = File.dirname(__FILE__)

# root
$root = TkRoot.new{
  title "Battleships GUY Using Ruby/Tk"
}

# tk
$tk_version = Tk::TK_VERSION
$tk_major_ver, $tk_minor_ver = $tk_version.split('.').map{|n| n.to_i}
$tk_patchlevel = Tk::TK_PATCHLEVEL


debug_me{[ '$tk_version', '$tk_major_ver', '$tk_minor_ver', '$tk_patchlevel' ]}


# tcl_platform
$tk_platform = TkVarAccess.new('tcl_platform')

# Set the default font
$font = TkFont.new('Helvetica -12')


# images
$image = Hash.new

$image['refresh'] = TkPhotoImage.new(
    height:  16,
    format:  'GIF',
    data:    <<~EOD
      R0lGODlhEAAQAPMAAMz/zCpnKdb/1z9mPypbKBtLGy9NMPL/9Or+6+P+4j1Y
      PwQKBP7//xMLFAYBCAEBASH5BAEAAAAALAAAAAAQABAAAwR0EAD3Gn0Vyw0e
      ++CncU7IIAezMA/nhUqSLJizvSdCEEjy2ZIV46AwDAoDHwPYGSoEiUJAAGJ6
      EDHBNCFINW5OqABKSFk/B9lUa94IDwIFgewFMwQDQwCZQCztTgM9Sl8SOEMG
      KSAthiaOjBMPDhQONBiXABEAOw==
  EOD
)


$image['view'] = TkPhotoImage.new(
  height:  16,
  format:  'GIF',
  data:    <<~EOD
    R0lGODlhEAAQAPMAAMz/zP///8DAwICAgH9/fwAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAACH5BAEAAAAALAAAAAAQABAAAwRIcMhJB7h3hM33
    KFjWdQQYap1QrCaGBmrRrS4nj5b53jOgbwXBKGACoYLDIuAoHCmZyYvR1rT5
    RMAq8LqcIYGsrjPsW1XOmFUEADs=
  EOD
)


$image['delete'] = TkPhotoImage.new(
  height:  16,
  format:  'GIF',
  data:    <<~EOD
    R0lGODlhEAAOAKEAAIQAAO/n3v///////yH5BAEKAAIALAAAAAAQAA4AAAIm
    lI9pAKHbIHNoVhYhTdjlJ2AWKG2g+CldmB6rxo2uybYhbS80eRQAOw==
  EOD
)


$image['print'] = TkPhotoImage.new(
  height:  19,
  format:  'GIF',
  data:    <<~EOD
    R0lGODlhGgATAPcAACEQOTEpQjEpUkIpc0IxY0I5c0oxjEo5SlJCY1JCe1JK
    UlpChFpCjFpGkFpSc1paa2NKc2NKnGNja2tapWtjc29KnHNanHNjc3NjrXNr
    jHNrnHNzc3tjpXtrtXtzhICAgIRzvYSEjIZzqox7tYyEnIyMjJSEtZSEvZSM
    lJyMtZyMvZyUlJyUrZyUvZycnKWctaWlpa2czq2lzrWtvbWtzrW1tb21xr21
    1sa9zs693s7OztbO3tbO597W1t7W7+fe7+fn5////+/n7+/v7+/v9////wAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAACH5BAEAAEEALAAAAAAaABMAQAj/AIMIHBhkg0GC
    CBMGIQEiQgseQT4oeCBBAokgRYYQ0JBixg8hRIiUUEBBYYmTByBwiCBCRYwH
    CxY8cKFw4AogRXLqLAJkQ80gCBBg3BkxZswTNGh4MGqgQQUMJRHCwMkTSE+D
    Pn8eCKBhxIMhO3ei2OHDBw6sWSlMMMoWgwwfMDZI8GBjx44NARZwEGGi5MkS
    PcIWKRGz5YgLbAco+KkQBQoJIRgjdGEVq+SaJajqtNrzMgsPCmoIzqmDgmWE
    KOBuUKAAwYabYTfs4OHjY0giGyhk4MAWRI4eKyRQqPgggYUXPH4A+XBAgwoK
    DiIsCFxjA9sFEVQQCRJCAYAFDJxiKhAxvMTonEFimrhhYinTBgWiCvxLNX3M
    DkkpsKV5OYhjBxCMYAICAigUEAA7
  EOD
)


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

# NOTE: Is this testing for a color display?
if TkWinfo.depth($root) == 1
  debug_me "depth is one"
  tag_demo = TkTextTag.new(
    txt,
    'lmargin1'  => '1c',
    'lmargin2'  => '1c',
    'underline' => 1
    )

  $tag_visited = TkTextTag.new(
    txt,
    'lmargin1'  => '1c',
    'lmargin2'  =>'1c',
    'underline' =>1
  )

  tag_hot = TkTextTag.new(
    txt,
    'background'  => 'black',
    'foreground'  => 'white'
  )
else
  debug_me "depth is NOT one"

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
end # if TkWinfo.depth($root) == 1


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
end # def showVars2(parent, *args)




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


def eval_samplecode(code, file=nil)
  #eval(code)
  #_null_binding.pseudo_toplevel_eval{ eval(code) }
  #Thread.new{ _null_binding.pseudo_toplevel_eval{ eval(code) } }
  Thread.new{
    _null_binding.pseudo_toplevel_eval{
      begin
        if file
          eval(code, binding, "(eval:#{file})")
        else
          eval(code)
        end
      rescue Exception=>e
        #p e
        TkBgError.show(e.class.inspect + ': ' + e.message + "\n" +
                         "\n---< backtrace of Ruby side >-----\n" +
                         e.backtrace.join("\n") +
                         "\n---< backtrace of Tk side >-------")
      end
    }
  }
  Tk.update rescue nil
end # def eval_samplecode(code, file=nil)



# SMELL: Not needed for the Battleship game
# invoke --
# This procedure is called when the user clicks on a demo description.
# It is responsible for invoking the demonstration.
#
# Arguments:
# txt -         Name of text widget
# index -       The index of the character that the user clicked on.
def invoke(txt, idx)
  tag = txt.tag_names(idx).find{|t| t.kind_of?(String) && t =~ /^demo-/}
  return unless tag

  cursor = txt.cget('cursor')
  txt.cursor('watch')
  Tk.update rescue nil
  # eval(IO.readlines("#{[$demo_dir, tag[5..-1]].join(File::Separator)}.rb").join, _null_binding)
  # Tk.update
  eval_samplecode(IO.readlines("#{[$demo_dir, tag[5..-1]].join(File::Separator)}.rb").join, tag[5..-1] + '.rb')
  txt.cursor(cursor)

  $tag_visited.add("#{idx} linestart +1 chars", "#{idx} lineend +1 chars")
end # def invoke(txt, idx)



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



# SMELL: Note needed for the Battleship game
# showCode --
# This procedure creates a toplevel window that displays the code for
# a demonstration and allows it to be edited and reinvoked.
#
# Arguments:
# demo -        The name of the demonstration's window, which can be
#               used to derive the name of the file containing its code.

def showCode(demo)
  file = "#{demo}.rb"
  $code_window = nil unless defined? $code_window
  if $code_window == nil || TkWinfo.exist?($code_window) == false
    $code_window = TkToplevel.new(nil)
    tf = TkFrame.new($code_window)
    $code_text = TkText.new(tf, :font=>'Courier 10', :height=>30,
                            :wrap=>'word', :bd=>1, :setgrid=>true,
                            :highlightthickness=>0, :pady=>2, :padx=>3)
    xscr = TkScrollbar.new(tf, :bd=>1){assign($code_text)}
    yscr = TkScrollbar.new(tf, :bd=>1){assign($code_text)}
    TkGrid($code_text, yscr, :sticky=>'news')
    #TkGrid(xscr)
    tf.grid_rowconfigure(0, :weight=>1)
    tf.grid_columnconfigure(0, :weight=>1)

    bf = TkFrame.new($code_window)

    lf = TkFrame.new(bf)
    TkLabel.new(lf, :text=>'line:').pack(:side=>:left)
    linenum =TkLabel.new(lf, :text=>'').pack(:side=>:left)
    TkLabel.new(lf, :text=>'  pos:').pack(:side=>:left)
    posnum =TkLabel.new(lf, :text=>'').pack(:side=>:left)

    $set_linenum = proc{|w|
      line, pos = w.index('insert').split('.')
      linenum.text = line
      posnum.text  = pos
    }

    b_dis = TkButton.new(bf, :text=>'Dismiss', :default=>:active,
                         :command=>proc{
                           $code_window.destroy
                           $code_window = nil
                         },
                         :image=>$image['delete'], :compound=>:left)
    b_prn = TkButton.new(bf, :text=>'Print Code',
                         :command=>proc{printCode($code_text, file)},
                         :image=>$image['print'], :compound=>:left)
    b_run = TkButton.new(bf, :text=>'Rerun Demo',
                         :command=>proc{
                           # eval($code_text.get('1.0','end'), _null_binding)
                           eval_samplecode($code_text.get('1.0','end'), '<viewer>')
                         },
                         :image=>$image['refresh'], :compound=>:left)

    TkGrid(lf, 'x', b_run, b_prn, b_dis, :padx=>4, :pady=>[6,4])
    bf.grid_columnconfigure(1, :weight=>1)

    TkGrid(tf, :sticky=>'news')
    TkGrid(bf, :sticky=>'ew')
    $code_window.grid_columnconfigure(0, :weight=>1)
    $code_window.grid_rowconfigure(0, :weight=>1)

    $code_window.bind('Return', proc{|win|
                        b_dis.invoke unless win.kind_of?(TkText)
                      }, '%W')
    $code_window.bindinfo('Return').each{|cmd, arg|
      $code_window.bind_append('Escape', cmd, arg)
    }

    btag = TkBindTag.new

    btag.bind('Key', $set_linenum, '%W')
    btag.bind('Button', $set_linenum, '%W')
    btag.bind('Configure', $set_linenum, '%W')

    btags = $code_text.bindtags
    btags.insert(btags.index($code_text.class) + 1, btag)
    $code_text.bindtags = btags

  else
    $code_window.deiconify
    $code_window.raise
  end

  $code_window.title("Demo code: #{file}")
  $code_window.iconname(file)
  fid = open([$demo_dir, file].join(File::Separator), 'r')
  $code_text.delete('1.0', 'end')
  $code_text.insert('1.0', fid.read)
  TkTextMarkInsert.new($code_text,'1.0')

  $set_linenum.call($code_text)

  fid.close
end # def showCode2(demo)




# SMELL: Note needed for the Battleship game
# printCode --
# Prints the source code currently displayed in the See Code dialog.
# Much thanks to Arjen Markus for this.
#
# Arguments:
# txt -         Name of text widget containing code to print
# file -        Name of the original file (implicitly for title)

def printCode(txt, file)
  code = txt.get('1.0', 'end - 1c')
  dir = '.'
  dir = ENV['HOME'] if ENV['HOME']
  dir = ENV['TMP'] if ENV['TMP']
  dir = ENV['TEMP'] if ENV['TEMP']

  fname = [dir, 'tkdemo-' + file].join(File::Separator)
  open(fname, 'w'){|fid| fid.print(code)}
  begin
    case Tk::TCL_PLATFORM('platform')
    when 'unix'
      msg = `lp -c #{fname}`
      unless $?.exitstatus == 0
        Tk.messageBox(:title=>'Print spooling failure',
                      :message=>'Print spooling probably failed: ' + msg)
      end
    when 'windows'
      begin
        printTextWin32(fname)
      rescue => e
        Tk.messageBox(:title=>'Print spooling failure',
                      :message=>'Print spooling probably failed: ' +
                      e.message)
      end
    when 'macintosh'
      Tk.messageBox(:title=>'Operation not Implemented',
                    :message=>'Oops, sorry: not implemented yet!')
    else
      Tk.messageBox(:title=>'Operation not Implemented',
                    :message=>'Wow! Unknown platform: ' +
                    Tk::TCL_PLATFORM('platform'))
    end
  ensure
    File.delete(fname)
  end
end # def printCode(txt, file)


# printTextWin32 --
#    Print a file under Windows
#
# Arguments:
# filename -            Name of the file
#
def printTextWin32(fname)
  require 'win32/registry'
  begin
    app = Win32::Registry::HKEY_CLASSES_ROOT['.txt']
    pcmd = nil
    Win32::Registry::HKEY_CLASSES_ROOT.open("#{app}\\shell\\print"){|reg|
      pcmd = reg['command']
    }
  rescue
    app = Tk.tk_call('auto_execok', 'notepad.exe')
    pcmd = "#{app} /p %1"
  end

  pcmd.gsub!('%1', fname)
  puts pcmd
  cmd = Tk.tk_call('auto_execok', 'start') + ' /min ' + pcmd

  msg = `#{cmd}`
  unless $?.exitstatus == 0
    fail RuntimeError, msg
  end
end # def printTextWin32(fname)



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

