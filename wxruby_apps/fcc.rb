#!/usr/bin/env ruby
#####################################################
###
##    File:  fcc.rb
##    Desc:  A rudimentary Fire Control console
##
## TODO: Insert into the counter_fire_gsma_gui.rb file
## TODO: Figure out a way to make it work with event machine; maybe threads
#


$rff_cff_text = "RequestForFire / CallForFire details\nwill appear in this area."




begin
  require 'rubygems' 
rescue LoadError
end
require 'wx'
require 'pp'
require 'ostruct'
require 'eventmachine'

module EchoServer
  def receive_data data
    send_data ">>>you sent: #{data}"
#    close_connection if data =~ /quit/i
    EventMachine::stop_event_loop if data =~ /quit/i
    $txt.set_value(data)
    $frame.show(true)
  end
end

$blue_launchers = []

$blue_launchers << OpenStruct.new
$blue_launchers.last.name      = "cf_launcher_01"
$blue_launchers.last.position  = [0,0,0]
$blue_launchers.last.selected  = false


$blue_launchers << OpenStruct.new
$blue_launchers.last.name      = "cf_launcher_02"
$blue_launchers.last.position  = [0,0,0]
$blue_launchers.last.selected  = false


$blue_launchers << OpenStruct.new
$blue_launchers.last.name      = "cf_launcher_03"
$blue_launchers.last.position  = [0,0,0]
$blue_launchers.last.selected  = false


$blue_launchers << OpenStruct.new
$blue_launchers.last.name      = "cf_launcher_04"
$blue_launchers.last.position  = [0,0,0]
$blue_launchers.last.selected  = false


class IseFrame < Wx::Frame
  def initialize(title, pos, size, style = Wx::DEFAULT_FRAME_STYLE)
    super(nil, -1, title, pos, size, style)


    file_menu = Wx::Menu.new()
    file_menu.append(Wx::ID_EXIT, "E&xit\tAlt-X", "Quit this program")
    evt_menu(Wx::ID_EXIT) { on_quit }
    
    help_menu = Wx::Menu.new()
    help_menu.append(Wx::ID_ABOUT, "&About FCC ...\tF1", "Show about dialog")
    evt_menu(Wx::ID_ABOUT) { on_about }
    
    menubar = Wx::MenuBar.new()
    menubar.append(file_menu, "&File")
    menubar.append(help_menu, "&Help")
    set_menu_bar(menubar)

    create_status_bar(2)
    set_status_text("ISE Simulation Support Component")


    # Start creating the sashes - these are created from outermost
    # inwards. 
    sash = Wx::SashLayoutWindow.new(self, -1, Wx::DEFAULT_POSITION,
      Wx::Size.new(150, self.get_size.y) )
    # The default width of the sash is 150 pixels, and it extends the
    # full height of the frame
    sash.set_default_size( Wx::Size.new(150, self.get_size.y) )
    
    # This sash splits the frame top to bottom
    sash.set_orientation(Wx::LAYOUT_VERTICAL)
    
    # Place the sash on the left of the frame
    sash.set_alignment(Wx::LAYOUT_LEFT)
    
    # Show a drag bar on the right of the sash
    sash.set_sash_visible(Wx::SASH_RIGHT, true)
    sash.set_background_colour(Wx::Colour.new(225, 200, 200) )

    panel = Wx::Panel.new(sash)
    v_siz = Wx::BoxSizer.new(Wx::VERTICAL)
    
    $blue_launchers.each_with_index do |bl, x|
      cb_item = Wx::CheckBox.new(panel, x, bl.name)
      v_siz.add(cb_item, 0, Wx::ADJUST_MINSIZE)
    end
    
    evt_checkbox(-1) {|event| on_checkbox(event) }
    
    panel.set_sizer_and_fit(v_siz)

    # handle the sash being dragged
    evt_sash_dragged( sash.get_id ) { | e | on_v_sash_dragged(sash, e) }

    # Create another small sash on the bottom of the frame
    sash_2 = Wx::SashLayoutWindow.new(self, -1, Wx::DEFAULT_POSITION,
      Wx::Size.new(self.get_size.x,
        100),
      Wx::SW_3DSASH)
    sash_2.set_default_size( Wx::Size.new(self.get_size.x, 100) )
    sash_2.set_orientation(Wx::LAYOUT_HORIZONTAL)
    sash_2.set_alignment(Wx::LAYOUT_BOTTOM)
    sash_2.set_sash_visible(Wx::SASH_TOP, true)
    #    text = Wx::StaticText.new(sash_2, -1, "Put some buttons in this area")

    sizer_top = Wx::BoxSizer.new(Wx::VERTICAL)

    @btn_1 = Wx::Button.new(sash_2, 1, "Engage with Designated Fire Units")
    @btn_2 = Wx::Button.new(sash_2, 2, "Engage with Most Capable Fire Unit")
    @btn_3 = Wx::Button.new(sash_2, 3, "Do Not Engage This Target")

    sizer_top.add(@btn_1, 0, Wx::ALIGN_LEFT | Wx::ALL, 5)
    sizer_top.add(@btn_2, 0, Wx::ALIGN_LEFT | Wx::ALL, 5)
    sizer_top.add(@btn_3, 0, Wx::ALIGN_LEFT | Wx::ALL, 5)

    set_auto_layout(true)
    set_sizer(sizer_top)

    sizer_top.set_size_hints(sash_2)
    sizer_top.fit(sash_2)

    @btn_2.set_focus()
    @btn_2.set_default()
    
    evt_button(-1) {|event| on_button(event) }

    evt_sash_dragged( sash_2.get_id ) { | e | on_h_sash_dragged(sash_2, e) }


    # The main panel - the residual part of the frame that takes up all
    # remaining space not used by the sash windows.
    @m_panel = Wx::Panel.new(self, -1)
    sizer = Wx::BoxSizer.new(Wx::VERTICAL)

    $txt  = Wx::TextCtrl.new(@m_panel, -1, $rff_cff_text,
      Wx::DEFAULT_POSITION, Wx::DEFAULT_SIZE,
      Wx::SUNKEN_BORDER|Wx::TE_MULTILINE)


    pp $txt

    pp $txt.methods.sort

    puts $txt.get_value

    $txt.set_value("Hello World")

    sizer.add($txt, 1, Wx::EXPAND|Wx::ADJUST_MINSIZE|Wx::ALL, 10)
    @m_panel.set_sizer_and_fit(sizer)

    # Adjust the size of the sashes when the frame is resized
    evt_size { | e | on_size(e) }

    # Call LayoutAlgorithm#layout_frame to layout the sashes.
    # The second argument is the residual window that takes up remaining
    # space
    Wx::LayoutAlgorithm.new.layout_frame(self, @m_panel)
  end

  def on_checkbox(event)
    id        = event.get_id
    selected  = event.is_checked
    $blue_launchers[id].selected = selected
  end

  def on_button(event)
    id = event.get_id

=begin    
    Wx::message_box("Button #{id} pressed", "Info",
                Wx::OK | Wx::ICON_INFORMATION, self)
=end
    assigned_fire_units = []         
    case id
    when @btn_1.get_id
      puts "1"
      $blue_launchers.each do |bl|
        assigned_fire_units << bl if bl.selected
      end
    when @btn_2.get_id
      puts "2"
      assigned_fire_units << $blue_launchers[rand($blue_launchers.length)]
    when @btn_3.get_id
      puts "3"
    else
      event.skip()
    end

    if assigned_fire_units.empty?
      a_msg = "Please confirm DO NOT ENGAGE."
    else

      a_msg = "The following fire units have been selected to engage this target:\n\n"
    
      assigned_fire_units.each do |afu|
        a_msg += "\t" + afu.name + "\n"
      end

      a_msg += "\n"
    end
    
    a_dialog = Wx::MessageDialog.new(nil,
      "Button #{id} pressed\n\n" + a_msg,
      "Confirm Engagement", 
      Wx::NO_DEFAULT | Wx::YES_NO | Wx::CANCEL | Wx::ICON_INFORMATION)

    case a_dialog.show_modal()
    when Wx::ID_YES
      puts "yes"
    when Wx::ID_NO
      puts "no"
    when Wx::ID_CANCEL
      puts "cancel"
    else
      puts "something else"
    end

  end
  
  
  def on_v_sash_dragged(sash, e)
    # Call get_drag_rect to get the new size
    size = Wx::Size.new(  e.get_drag_rect.width(), self.get_size.y )
    sash.set_default_size( size )
    Wx::LayoutAlgorithm.new.layout_frame(self, @m_panel)
  end

  def on_h_sash_dragged(sash, e)
    size = Wx::Size.new( self.get_size.x, e.get_drag_rect.height() )
    sash.set_default_size( size )
    Wx::LayoutAlgorithm.new.layout_frame(self, @m_panel)
  end

  def on_size(e)
    e.skip()
    Wx::LayoutAlgorithm.new.layout_frame(self, @m_panel)
  end

  def on_quit
    close(true)
  end

  def on_about
    msg =  sprintf("FCC is an ISE component  It is " \
        "a rudimentary implementation to simulation only a small part of a FIRES " \
        "control node.  This implementation responds to MissileDetected " \
        "messages from Search Radars.  It presents a list of available " \
        "fire units which are capable of engaging the launch coordinates " \
        "of the detected missile.\n\n" \
        "The Integrated System Environment (ISE) is a distributed network " \
        "communications middleware technology " \
        "which ties together existing legacy systems and simulations " \
        "using a protocol conversion concept that allows systems " \
        "not specifically designed for interoperability to communicate.\n\n" \
        "The FCC is prototyped in Ruby using the %s cross-platform GUI library.\n\n" \
        "Copyright (c) 2009 Lockheed Martin Corp.", Wx::VERSION_STRING)
    Wx::message_box(msg, "FIRES Control Console (FCC)", Wx::OK|Wx::ICON_INFORMATION, self)
  end
end

class SashApp < Wx::App
  def on_init
    $frame = IseFrame.new("FIRES Control Console (rudimentary)",
      Wx::Point.new(50, 50),
      Wx::Size.new(450, 340))

    $frame.hide(true)

  end
end

app = SashApp.new

gui = Thread.new do
  puts "inside new thread; starting gui loop"
  app.main_loop()
  EventMachine::stop_event_loop
end

gui.priority = -2

Thread.main.priority = -1

puts "main thread starting eventmachine loop"
EventMachine::run {
  EventMachine::start_server "localhost", 8081, EchoServer
}

puts "event machine has terminated"

Thread.kill(gui) if gui.alive?

puts "thread was told to kill gui"