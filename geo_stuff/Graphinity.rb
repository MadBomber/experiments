#!/usr/bin/ruby -w

=begin
/***************************************************************************
 *   Copyright (C) 2008, Paul Lutus                                        *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/
=end

require 'graphinityui_ui'

require 'graphinityhelp'

include Math # this allows use of math functions without "Math." prefix

PROGRAM_VERSION = "2.4"

class Graphinity < GraphinityuiGlade
   attr_reader :program_title
   attr_reader :ini_file
   attr_accessor :graphic_pane
   attr_reader :config
   attr_reader :mouse_x_pos
   attr_reader :mouse_y_pos

   def initialize(path,xxx,name)
      super(path,xxx,name)
      @graphic_pane = nil
      @config = nil
      get_widgets()
      @mouse_press_x = nil
      @mouse_x_pos = nil
      @mouse_y_pos = nil
      @program_name = self.class.name
      @program_title = @program_name + " " + PROGRAM_VERSION
      GraphinityUI().set_title(@program_title)
      @anaglyphComboManager = ComboBoxManager.new(anaglyphicComboBox(),[ "None","Black","White" ])
      @config = Configuration.new
      @conf_handler = ConfigurationHandler.new(@config,self)
      @ini_file = @conf_handler.ini_file
      @help_engine = GraphinityHelp.new(self)
      fd = Pango::FontDescription.new("monospace,normal,12")
      helpTextEdit().modify_font(fd)
      helpTextEdit().modify_bg(Gtk::STATE_NORMAL,Gdk::Color.new(255,255,255))
      @graph_engine_2d = GraphEngine2d.new(self)
      @graph_engine_3d = GraphEngine3d.new(self)
      load_conf_values()
      [ graphicPane1(), graphicPane2()].each do |pane|
         pane.signal_connect("expose_event") do
            draw_image
         end
      end
      switch_tabs(controlTabWidget().page)
      set_panes_tooltip(twoThreeTabWidget().page)
   end

   def get_widgets()
      @glade.widget_names.each do |name|
         # create accessor methods for each defined widget
         eval("def #{name}() return @glade.get_widget(\"#{name}\") end")
         # associate events with actions
         w = @glade.get_widget("#{name}")
         if(w.class.name =~ /Gtk::Entry/)
            w.signal_connect('activate') { draw_image(true) }
            # don't scramble equations with mouse wheel
            unless(name =~ /equation/i)
               w.signal_connect('scroll_event') { |wid,evt| mouse_scroll_event(wid,evt) }
            end
         end
      end
   end

   def switch_tabs(m)
      case m
      when 0 then @graphic_pane = graphicPane1()
      when 1 then @graphic_pane = graphicPane2()
      when 2 then force_focus(helpSearchLineEdit())
      end
      draw_image if m < 2
   end

   def current_mode()
      return twoThreeTabWidget().page
   end

   # a hack to allow a reliable focus shift

   def force_focus(obj)
      Thread.new { sleep 0.1; obj.grab_focus }
   end

   def beep
      Gdk.beep
   end

   def status_bar(s)
      statusBarLabel().text = s
   end

   def Graphinity::message_dialog(window,message,inquiry = false)
      if inquiry
         dlg = Gtk::MessageDialog.new(nil,
         Gtk::MessageDialog::MODAL,
         Gtk::MessageDialog::QUESTION,
         Gtk::MessageDialog::BUTTONS_YES_NO,
         message)
      else # just an alert
         dlg = Gtk::MessageDialog.new(nil,
         Gtk::MessageDialog::MODAL,
         Gtk::MessageDialog::INFO,
         Gtk::MessageDialog::BUTTONS_OK,
         message)
      end
      dlg.set_title(window.class.name)
      response = dlg.run
      dlg.destroy
      return response == Gtk::MessageDialog::RESPONSE_YES || response == Gtk::MessageDialog::RESPONSE_OK
   end

   def create_control_array
      @control_array = [
         [:app_xpos,@app_x],
         [:app_ypos,@app_y],
         [:app_xsize,@app_width],
         [:app_ysize,@app_height],
         [:anaglyph_mode,anaglyphicComboBox()],
         [:equation_2d,equation2DLineEdit()],
         [:equation_3d,equation3DLineEdit()],
         [:x_axis_label,xLabelLineEdit()],
         [:y_axis_label,yLabelLineEdit()],
         [:chart_title,chartTitleLineEdit()],
         [:x_nums,xIndexCheckBox()],
         [:y_nums,yIndexCheckBox()],
         [:border ,borderCheckBox()],
         [:x_min2d,xMin2DLineEdit()],
         [:x_max2d,xMax2DLineEdit()],
         [:y_min2d,yMin2DLineEdit()],
         [:y_max2d,yMax2DLineEdit()],
         [:x_min3d,xMin3DLineEdit()],
         [:x_max3d,xMax3DLineEdit()],
         [:y_min3d,yMin3DLineEdit()],
         [:y_max3d,yMax3DLineEdit()],
         [:z_min3d,zMin3DLineEdit()],
         [:z_max3d,zMax3DLineEdit()],
         [:x_grid_steps,xGridStepsLineEdit()],
         [:y_grid_steps,yGridStepsLineEdit()],
         [:plot_steps_2d,plotSteps2DLineEdit()],
         [:plot_steps_3d,plotSteps3DLineEdit()],
         [:control_var_a,controlALineEdit()],
         [:control_var_b,controlBLineEdit()],
         [:control_var_c,controlCLineEdit()],
         [:line_thickness,lineThicknessLineEdit()],
         [:current_control_tab,controlTabWidget()],
         [:current_display_tab,twoThreeTabWidget()]
      ]
   end

   def save_control(val,con)
      result = -1
      case con.class.to_s
      when "Gtk::ComboBox" then result = con.active
      when "Gtk::CheckButton" then result = con.active?
      when "Gtk::SpinButton" then result = con.value
      when "Gtk::Notebook" then result = con.page
      when "Fixnum" then result = con
      when "Float" then result = con
      when "Gtk::Entry" then result = con.text
      end
      return result
   end

   def load_control(val,con)
      case con.class.to_s
      when "Gtk::ComboBox" then con.active = val.to_i
      when "Gtk::CheckButton" then con.active = val
      when "Gtk::SpinButton" then con.value = val
      when "Gtk::Notebook" then con.page = val.to_i
      when "Fixnum" then con = val.to_i
      when "Float" then con = val.to_f
      when "Gtk::Entry" then con.text = val.to_s
      end
   end

   def get_app_dims
      @app_width,@app_height = GraphinityUI().window.size
      @app_x,@app_y = GraphinityUI().window.position
   end

   def save_conf_values()
      get_app_dims
      create_control_array
      @control_array.each do |item|
         r = item[0].to_s + "="
         v = @config.send(item[0])
         @config.send(r, save_control(v,item[1]))
      end
      @conf_handler.writeConfig
   end

   def load_conf_values()
      get_app_dims
      create_control_array
      @conf_handler.readConfig
      @control_array.each do |item|
         load_control(@config.send(item[0]),item[1])
      end
      if(@config.app_xpos != -1)
         GraphinityUI().move(@config.app_xpos,@config.app_ypos)
         GraphinityUI().resize(@config.app_xsize,@config.app_ysize)
      end
   end

   def set_panes_tooltip(pane)
      tip = (pane != 1) ? "Drag mouse = data, right-click = copy image to clipboard" : "Drag mouse to rotate, zoom with wheel, right-click = copy image to clipboard"
      graphicPane1().set_tooltip_text(tip)
      graphicPane2().set_tooltip_text(tip)
   end

   # mode 0 = 2d equation entered
   # mode 1 = 3d equation entered

   def draw_image(reset = false,mode = -1)
      if(mode >= 0)
         @config.graphic_mode = mode
      end
      if @graphic_pane && @graph_engine_2d && @graph_engine_3d
         case @config.graphic_mode
         when 0
            @graph_engine_2d.graph_equation(equation2DLineEdit(),"|x,y,a,b,c|",reset)
         when 1
            @graph_engine_3d.graph_equation(equation3DLineEdit(),"|x,y,z,a,b,c|",reset)
         end
      end
   end

   def Graphinity::col_to_rgb(col)
      return col.red,col.green,col.blue
   end

   def Graphinity::rgb_to_col(r,g,b)
      return Gdk::Color.new(r,g,b)
   end

   def Graphinity::fixnum_to_col(n)
      b = n & 255
      n >>= 8
      g = n & 255
      n >>= 8
      r = n & 255
      return Gdk::Color.new(r <<= 8,g <<= 8,b <<= 8)
   end

   def Graphinity::col_to_fixnum(col)
      result = (((col.red >> 8) & 255) << 16) | (((col.green >> 8) & 255) << 8) | ((col.blue >> 8) & 255)
      return result
   end

   def setColor(col)
      dialog = Gtk::ColorSelectionDialog.new("Color Selection")
      init = Graphinity::fixnum_to_col(col)
      dialog.colorsel.current_color = init
      result = dialog.run
      if result = Gtk::Dialog::RESPONSE_OK
         col = dialog.colorsel.current_color
      end
      dialog.destroy
      return Graphinity::col_to_fixnum(col)
   end

   # override parent class close method

   def close(*x)
      save_conf_values
      Gtk.main_quit
   end

   # use mouse motion to rotate 3D drawing

   def mouse_move_event (e)
      if(@mouse_press_x)
         @mouse_x_pos = e.x
         @mouse_y_pos = e.y
         if(current_mode() == 1)
            dx = (e.y - @mouse_press_x) / 2.0
            dy = (e.x - @mouse_press_y) / 2.0
            @config.rotx = (@mouse_press_rx - dx) % 360
            @config.roty = (@mouse_press_ry - dy) % 360
            xa = @config.rotx.to_i
            xa = -360 + xa if xa > 180
            s = sprintf("x = %3d°, y = %3d°",xa,@config.roty.to_i)
            status_bar(s)
         end
         draw_image
      end
   end

   # mouse right-click

   def mouse_context(e)
      if(@graph_engine_2d && @graph_engine_3d)
         case @config.graphic_mode
         when 0
            map = @graph_engine_2d.pixmap
         when 1
            map = @graph_engine_3d.pixmap
         end
         alloc = graphic_pane().allocation
         xsize = alloc.width
         ysize = alloc.height
         buf = Gdk::Pixbuf.from_drawable(nil,map,0,0,xsize,ysize)
         Gtk::Clipboard.get(GraphinityUI().display,Gdk::Selection::CLIPBOARD).image = buf
         status_bar("Image copied to clipboard.")
      end
   end

   # start mouse action

   def mouse_press_event (e)
      if(e.button == 3)
         mouse_context(e)
      else
         # set up to control rotation
         # by dragging mouse
         @mouse_x_pos = e.x
         @mouse_y_pos = e.y
         @mouse_press_rx = @config.rotx
         @mouse_press_ry = @config.roty
         @mouse_press_x = e.y
         @mouse_press_y = e.x
      end
      draw_image
   end

   # stop mouse action

   def mouse_release_event (e)
      @mouse_press_x = nil
      @mouse_x_pos = nil
      draw_image
   end

   def mouse_scroll_event (w,e)
      # get mouse wheel delta
      delta = (e.direction == Gdk::EventScroll::DOWN)?-1:1
      if(w.class.name =~ /EventBox/)
         @config.drawing_scale *= 1.0 + (delta * 0.1)
      elsif(w.class.name =~ /Entry/)
         s = w.text
         if(s =~ /\d/) # if some numeric digits
            sv = s.sub(%r{[-+\.\d]+(.*)},"\\1")
            nv = s.to_f
            w.text = (nv+delta).to_s + sv
         end
      end
      draw_image
   end

   # event handlers

   def on_GraphinityUI_delete_event(widget, arg0)
      close
   end
   def on_helpSearchLineEdit_key_release_event(widget, arg0)
      ss = helpSearchLineEdit().text
      @help_engine.search(ss)
   end
   def on_controlTabWidget_switch_page(widget, arg0,arg1)
      switch_tabs(arg1)
   end
   def on_borderCheckBox_toggled(widget)
      draw_image
   end
   def on_yIndexCheckBox_toggled(widget)
      draw_image(true)
   end
   def on_xIndexCheckBox_toggled(widget)
      draw_image(true)
   end
   def on_anaglyphicComboBox_changed(widget)
      if @config
         @config.anaglyph_mode = widget.active
      end
      draw_image(true)
   end
   def on_quitPushButton_clicked(widget)
      close
   end
   def on_numberColorPushButton_clicked(widget)
      @config.number_color = setColor(@config.number_color)
      draw_image
   end
   def on_borderColorPushButton_clicked(widget)
      @config.border_color = setColor(@config.border_color)
      draw_image
   end
   def on_textColorPushButton_clicked(widget)
      @config.text_color = setColor(@config.text_color)
      draw_image
   end
   def on_backgroundColorPushButton_clicked(widget)
      @config.background_color = setColor(@config.background_color)
      draw_image
   end
   def on_plotColorPushButton_clicked(widget)
      @config.plot_color = setColor(@config.plot_color)
      draw_image
   end
   def on_gridColorPushButton_clicked(widget)
      @config.grid_color = setColor(@config.grid_color)
      draw_image
   end
   def on_twoThreeTabWidget_switch_page(widget, arg0, arg1)
      set_panes_tooltip(arg1)
      draw_image(true,arg1)
   end
   def on_eventbox1_scroll_event(widget, arg0)
      mouse_scroll_event(widget,arg0)
   end
   def on_eventbox1_button_press_event(widget, arg0)
      mouse_press_event(arg0)
   end
   def on_eventbox1_button_release_event(widget, arg0)
      mouse_release_event(arg0)
   end
   def on_eventbox1_motion_notify_event(widget, arg0)
      mouse_move_event(arg0)
   end
   def on_eventbox2_scroll_event(widget, arg0)
      mouse_scroll_event(widget,arg0)
   end
   def on_eventbox2_button_press_event(widget, arg0)
      mouse_press_event(arg0)
   end
   def on_eventbox2_button_release_event(widget, arg0)
      mouse_release_event(arg0)
   end
   def on_eventbox2_motion_notify_event(widget, arg0)
      mouse_move_event(arg0)
   end

end # class Graphinity

class ComboBoxManager
   def initialize(box,list,default = nil)
      @box = box
      @hash = {}
      index = 0
      # a placeholder item is required to get around
      # a bug in the Glade designer that won't create
      # a sane combobox without it. So first,
      # remove the placeholder item
      @box.remove_text(0)
      list.each do |item|
         @box.append_text(item)
         @hash[item] = index
         index += 1
      end
      if (@hash[default])
         @box.set_active(@hash[default])
      else
         @box.set_active(0)
      end
   end
   def active_string()
      return @box.active_text
   end
end

=begin
   The Configuration class defines program values
   to be read from and written to a configuration file.
=end

class Configuration
   attr_accessor :app_xpos
   attr_accessor :app_ypos
   attr_accessor :app_xsize
   attr_accessor :app_ysize
   attr_accessor :anaglyph_mode
   attr_accessor :graphic_mode
   attr_accessor :equation_2d
   attr_accessor :equation_3d
   attr_accessor :chart_title
   attr_accessor :x_axis_label
   attr_accessor :y_axis_label
   attr_accessor :plot_steps_2d
   attr_accessor :plot_steps_3d
   attr_accessor :line_thickness
   attr_accessor :x_nums
   attr_accessor :y_nums
   attr_accessor :border
   attr_accessor :x_min2d
   attr_accessor :x_max2d
   attr_accessor :y_min2d
   attr_accessor :y_max2d
   attr_accessor :x_min3d
   attr_accessor :x_max3d
   attr_accessor :y_min3d
   attr_accessor :y_max3d
   attr_accessor :z_min3d
   attr_accessor :z_max3d
   attr_accessor :x_grid_steps
   attr_accessor :y_grid_steps
   attr_accessor :control_var_a
   attr_accessor :control_var_b
   attr_accessor :control_var_c
   attr_accessor :rotx
   attr_accessor :roty
   attr_accessor :drawing_scale
   attr_accessor :border_color
   attr_accessor :grid_color
   attr_accessor :number_color
   attr_accessor :text_color
   attr_accessor :plot_color
   attr_accessor :background_color
   attr_accessor :current_control_tab
   attr_accessor :current_display_tab

   # default values

   def initialize
      @app_xpos = 100
      @app_ypos = 100
      @app_xsize = 600
      @app_ysize = 600
      @anaglyph_mode = 0
      @x_min2d = -3
      @x_max2d = 3
      @y_min2d = 0
      @y_max2d = 1
      @x_min3d = -3
      @x_max3d = 3
      @y_min3d = -0.25
      @y_max3d = 0.75
      @z_min3d = -3
      @z_max3d = 3
      @x_grid_steps = 8
      @y_grid_steps = 8
      @control_var_a = 1
      @control_var_b = 1
      @control_var_c = 1
      @rotx = -20.0
      @roty = -20.0
      @drawing_scale = 1.0
      @chart_title = "y = ?"
      @x_axis_label = "x"
      @y_axis_label = "y"
      @graphic_mode = 0
      @equation_2d = "E^-x^2"
      @equation_3d = "E^-(x^2+z^2)"
      @plot_steps_2d = 500
      @plot_steps_3d = 16
      @line_thickness = 1
      @border = true
      @x_nums = true
      @y_nums = true
      @border_color = 0x0
      @grid_color = 0xa0c0a0
      @number_color = 0x4040ff
      @text_color = 0x0
      @plot_color = 0xaa007f
      @background_color = 0xffffff
      @current_control_tab = 2
   end
end

# ConfigurationHandler reads and writes configuration

class ConfigurationHandler
   attr_reader :ini_file
   def initialize(conf,app)
      @conf = conf
      @prog_name = app.class.to_s
      @conf_path = File.join(ENV["HOME"], "." + @prog_name)
      @ini_file = @conf_path + "/" + @prog_name + ".ini"
      Dir.mkdir(@conf_path) unless FileTest.exists?(@conf_path)
   end
   def writeConfig
      file = File.new(@ini_file,"w")
      unless file.nil?
         @conf.instance_variables.sort.each { |x|
            xi = @conf.instance_variable_get(x)
            sx = x.sub(/@/,"")
            # escape strings
            if(xi.class == String)
               xi.gsub!(/\\/,"\\\\\\\\")
               xi.gsub!(/"/,"\\\"")
               xi = "\"#{xi}\""
            end
            file.write("#{sx}=#{xi}\n")
         }
         file.close()
      end
   end
   def readConfig
      if FileTest.exists?(@ini_file)
         file = File.new(@ini_file,"r")
         file.each { |line|
            line.strip!
            unless line =~ /^#/ # unless a comment line
               begin
                  @conf.instance_eval("@" + line)
               rescue Exception
               end
            end
         }
         file.close()
      end
   end
end

# a Cartesian 3D vector class
# with a number of important operator overrides

class Cart3
   attr_accessor :x,:y,:z
   def initialize(x = 0,y = 0,z = 0)
      if(x.class == self.class)
         @x = x.x
         @y = x.y
         @z = x.z
      else
         @x = x
         @y = y
         @z = z
      end
   end

   def -(e)
      Cart3.new(@x - e.x,@y - e.y,@z - e.z)
   end

   def +(e)
      Cart3.new(@x + e.x,@y + e.y,@z + e.z)
   end

   def *(e)
      if(e.class != self.class)
         # multiply by scalar
         Cart3.new(@x * e,@y * e,@z * e)
      else
         # multiply by vector
         Cart3.new(@x * e.x,@y * e.y,@z * e.z)
      end
   end

   def /(e)
      if(e.class != self.class)
         # divide by scalar
         Cart3.new(@x / e,@y / e,@z / e)
      else
         # divide by vector
         Cart3.new(@x / e.x,@y / e.y,@z / e.z)
      end
   end

   # sum of squares
   def sumsq
      @x*@x+@y*@y+@z*@z
   end

   def to_s
      "[#{CommonCode::fmt_num(@x)},#{CommonCode::fmt_num(@y)},#{CommonCode::fmt_num(@z)}]"
   end
end # class Cart3

# RotationMatrix performs 3D rotations and perspective

class RotationMatrix

   # perspective depth cue for 3D -> 2D transformation
   PerspectiveDepth = 8
   # empirical constant for anaglyphic rotation
   AnaglyphScale = 0.05

   RotationMatrix::ToRad = Math::PI / 180.0
   RotationMatrix::ToDeg = 180.0 / Math::PI

   # populate 3D matrix with values for x,y,z rotations

   def populate_matrix(xa,ya)

      # create trig values
      @sy = Math.sin(xa * RotationMatrix::ToRad);
      @cy = Math.cos(xa * RotationMatrix::ToRad);
      @sx = Math.sin(ya * RotationMatrix::ToRad);
      @cx = Math.cos(ya * RotationMatrix::ToRad);
   end

   # 3D -> 2D, add perspective cue,
   # perform anaglyphic perspective rotation if specified

   def convert_3d_to_2d(v,anaglyph_flag = 0)
      v.x = (v.x * (PerspectiveDepth + v.z))/PerspectiveDepth
      v.x += v.z * anaglyph_flag * AnaglyphScale if anaglyph_flag
      v.y = (v.y * (PerspectiveDepth + v.z))/PerspectiveDepth
   end

   # rotate a 3D point using matrix values

   def rotate(v)
      # borrowed from my "Apple World" 1979
      hf = (v.x * @sx - v.z * @cx)
      py = v.y * @cy + @sy * hf
      px = v.x * @cx + v.z * @sx
      pz = -v.y * @sy + @cy * hf
      v.x = px; v.y = py; v.z = pz
   end
end # class RotationMatrix


# parent class for the GraphEngine2d and GraphEngine3d classes

class GraphEngine
   attr_reader :pixmap
   def initialize(app)
      @parent = app
      @pixmap = nil
      @suspend_equation = false
      @old_xsize = -1
      @old_ysize = -1
      @text_color = nil
   end
   def ntrp(xa,xb,ya,yb,x)
      return 0 if(xb-xa == 0)
      return ((x-xa)/(xb-xa) * (yb-ya)) + ya;
   end
   def inside(x,a,b)
      return (x >= a && x <= b)
   end

   def max(*a)
      return a.max
   end

   def min(*a)
      return a.min
   end

   def error_dialog(title,msg)
      mb = Gtk::MessageDialog.new(@parent.GraphinityUI,
      Gtk::Dialog::DESTROY_WITH_PARENT,
      Gtk::MessageDialog::WARNING,
      Gtk::MessageDialog::BUTTONS_CLOSE,
      msg)
      mb.set_title(@parent.program_title + " " + title + " Error")
      mb.run
      mb.destroy
   end

   # deal with various common numerical entry errors
   def test_num(widget,s)
      r = s.gsub(/\.+/,".")
      r = r.gsub(/(^|\D+)(\.\d)/,"\\10\\2")
      if(r != s)
         widget.text = r
      end
      return r
   end

   def getSet(widget, default)
      a = @control_var_a
      b = @control_var_b
      c = @control_var_c
      s = widget.text.strip
      v = 0
      if s.size > 0
         s = test_num(widget,s)
         begin
            eval("v = #{s}.to_f")
         rescue Exception => err
            s = "0.0"
            widget.text = s
            @parent.status_bar("Numeric entry error")
            str = err.to_s.sub(/(.*)for.*/m,"\\1")
            error_dialog("Number entry",str)
         end
      else
         v = default
         widget.text = v.to_s
      end
      return v
   end

   def set_scale_vals()
      xa2d = -3.0
      xb2d = 3.0
      ya2d = -1.0
      yb2d = 1.0
      xa3d = -3.0
      xb3d = 3.0
      ya3d = -1.0
      yb3d = 1.0
      za3d = -3.0
      zb3d = 3.0
      xgs = 10
      ygs = 10
      ps2d = 500
      ps3d = 16
      ca = 1
      cb = 1
      cc = 1
      lt = 0
      @control_var_a = getSet(@parent.controlALineEdit,ca)
      @control_var_b = getSet(@parent.controlBLineEdit,cb)
      @control_var_c = getSet(@parent.controlCLineEdit,cc)
      @xa2d = getSet(@parent.xMin2DLineEdit,xa2d)
      @xb2d = getSet(@parent.xMax2DLineEdit,xb2d)
      @ya2d = getSet(@parent.yMin2DLineEdit,ya2d)
      @yb2d = getSet(@parent.yMax2DLineEdit,yb2d)
      @xa3d = getSet(@parent.xMin3DLineEdit,xa3d)
      @xb3d = getSet(@parent.xMax3DLineEdit,xb3d)
      @ya3d = getSet(@parent.yMin3DLineEdit,ya3d)
      @yb3d = getSet(@parent.yMax3DLineEdit,yb3d)
      @za3d = getSet(@parent.zMin3DLineEdit,za3d)
      @zb3d = getSet(@parent.zMax3DLineEdit,zb3d)
      @x_grid_steps = getSet(@parent.xGridStepsLineEdit,xgs)
      @y_grid_steps = getSet(@parent.yGridStepsLineEdit,ygs)
      @plot_steps_2d = getSet(@parent.plotSteps2DLineEdit,ps2d)
      @plot_steps_3d = getSet(@parent.plotSteps3DLineEdit,ps3d)
      @line_thickness = getSet(@parent.lineThicknessLineEdit,lt)
   end

   def create_font (font_desc)
      @pango_context = Gdk::Pango.context
      desc = Pango::FontDescription.new(font_desc)
      fm = @pango_context.get_metrics(desc)
      cw = fm.approximate_char_width / Pango::SCALE
      ch = (fm.ascent + fm.descent) / Pango::SCALE
      return desc,cw,ch
   end

   def set_sizes()
      alloc = @parent.graphic_pane().allocation
      xsize = alloc.width
      ysize = alloc.height
      if(xsize != @old_xsize || ysize != @old_ysize)
         @old_xsize = xsize
         @old_ysize = ysize
         @text_scale = (@old_xsize > @old_ysize)?(@old_ysize / 65.0):(@old_xsize / 65.0)
         @normal_font,@normal_char_width,@normal_char_height = create_font("Monospace, Normal, #{@text_scale}")
         @title_font,@title_char_width,@title_char_height = create_font("Monospace, Normal, #{1.5 * @text_scale}")
      end
      @bg_color = Graphinity::fixnum_to_col(@parent.config.background_color)
      if(@parent.borderCheckBox.active?)
         @internal_margin = 10
         @draw_border = true
      else
         @internal_margin = 8
         @draw_border = false
      end
      @chart_title = @parent.chartTitleLineEdit.text.strip
      set_scale_vals
      @line_thickness = (@line_thickness < 0)?0:(@line_thickness)
   end

   def graph_equation(widget,templ,reset)
      if(reset)
         @suspend_equation = false
         # if mouse is not down
         if(!@parent.mouse_x_pos)
            @parent.status_bar("OK")
         end
      end
      s = widget.text
      if(s.size > 0)
         if(!@suspend_equation)
            begin
               s = test_num(widget,s)
               # allow "^" as power symbol
               s.gsub!(/\^/,"**")
               @gproc = eval("Proc.new { #{templ} #{s} }")
            rescue Exception => err
               if(!@suspend_equation)
                  @suspend_equation = true
                  @parent.status_bar("Equation error")
                  str = err.to_s.sub(/.*(syntax.*)/m,"\\1")
                  error_dialog("Equation",str)
               end
            end
         end
      end
      draw_image()
   end

   def draw_line(gc,sx,sy,ex,ey)
      # guard against numeric values
      # beyond the range of an integer
      begin
         @pixmap.draw_line(gc,sx,sy,ex,ey)
      rescue
      end
   end

   def fill_block(gc,color,sx,sy,wx,wy)
      gc.fill = Gdk::GC::Fill::SOLID
      gc.rgb_fg_color = color
      @pixmap.draw_rectangle(gc,true,sx,sy,wx+2,wy+2)
   end

   def draw_text(text,gc,x,y,font_desc,color = @text_color)
      gc.rgb_fg_color = color
      layout = Pango::Layout.new(Gdk::Pango.context)
      layout.font_description = font_desc
      layout.text = text
      @pixmap.draw_layout(gc,x,y,layout)
   end
end

class GraphEngine3d < GraphEngine

   def initialize(app)
      super(app)
      @rotator = RotationMatrix.new
      @old_plot_steps_3d = -1
   end

   def draw_graph(gc,anaglyph_flag,color)
      @rotator.populate_matrix(@parent.config.rotx,@parent.config.roty)
      zi = 0
      gc.rgb_fg_color = color
      # declare array for precomputing drawing points
      if(@plot_steps_3d != @old_plot_steps_3d)
         @plot_steps_3d = (@plot_steps_3d <= 0)?1:@plot_steps_3d
         @point_array = Array.new(@plot_steps_3d+1) { Array.new(@plot_steps_3d+1) { [] } }
         @old_plot_steps_3d = @plot_steps_3d
      end
      # 1. fill the array with X,Z data
      while(zi <= @plot_steps_3d && !@suspend_equation)
         mz = ntrp(0,@plot_steps_3d,-1.0,1.0,zi.to_f)
         z = ntrp(0,@plot_steps_3d,@za3d,@zb3d,zi.to_f)
         xi = 0
         while(xi <= @plot_steps_3d && !@suspend_equation)
            mx = ntrp(0,@plot_steps_3d,-1.0,1.0,xi.to_f)
            x = ntrp(0,@plot_steps_3d,@xa3d,@xb3d,xi.to_f)
            y = 0
            begin
               y = @gproc.call(x,y,z,@control_var_a,@control_var_b,@control_var_c)
            rescue Exception => err
               if !@suspend_equation
                  s = err.to_s.sub(/(.*)for.*/,"\\1")
                  error_dialog("Execution",s)
               end
               y = 0
               @suspend_equation = true
            end
            if(!@suspend_equation)
               my = ntrp(@ya3d,@yb3d,-0.5,0.5,y)
               v = Cart3.new(mx,my,mz) * @parent.config.drawing_scale
               @rotator.rotate(v)
               @rotator.convert_3d_to_2d(v,anaglyph_flag)
               @point_array[xi][zi] = [ @x_screen_center + (v.x * @screen_scale),
               @y_screen_center - (v.y * @screen_scale) ]
            end
            xi += 1
         end
         zi += 1
      end # fill precomputing array
      if(!@suspend_equation)
         # 2. draw the precomputed array contents twice,
         # two orthogonal sets of lines
         oxa = oya = 0
         oxb = oyb = 0
         0.upto(@plot_steps_3d) do |yi|
            0.upto(@plot_steps_3d) do |xi|
               xa,ya = @point_array[yi][xi]
               xb,yb = @point_array[xi][yi]
               if(xi > 0)
                  draw_line(gc,oxa,oya,xa,ya)
                  draw_line(gc,oxb,oyb,xb,yb)
               end
               oxa,oya = xa,ya
               oxb,oyb = xb,yb
            end
         end
      end # draw precomputed results
   end

   def choose_anaglyph_color(color,black,white)
      case @parent.config.anaglyph_mode
      when 1
         color = white
      when 2
         color = black
      end
      return color
   end

   def draw_image()
      set_sizes
      @x_screen_center = @old_xsize / 2
      @y_screen_center = @old_ysize / 2
      @screen_scale = (@x_screen_center > @y_screen_center)?@y_screen_center:@x_screen_center
      @chart_title.gsub!(/\?/,@parent.equation3DLineEdit.text)
      return unless @parent.graphic_pane.window
      # use double-buffering
      @pixmap = Gdk::Pixmap.new(@parent.graphic_pane.window,@old_xsize,@old_ysize,-1)
      gc = Gdk::GC.new(@pixmap)
      gc.set_line_attributes(@line_thickness,Gdk::GC::LineStyle::SOLID,Gdk::GC::CapStyle::ROUND,Gdk::GC::JoinStyle::MITER)
      red = Gdk::Color.parse("red")
      cyan = Gdk::Color.parse("cyan")
      black = Gdk::Color.parse("black")
      white = Gdk::Color.parse("white")
      @gc_text = Gdk::GC.new(@pixmap)
      @text_color = Graphinity::fixnum_to_col(@parent.config.text_color)
      #puts "anaglyph mode: #{@parent.config.anaglyph_mode}"
      gc.function = Gdk::GC::COPY
      case @parent.config.anaglyph_mode
      when 0 # no anaglyphic display
         fill_block(gc,@bg_color,0,0,@old_xsize,@old_ysize)
         color = Graphinity::fixnum_to_col(@parent.config.plot_color)
         draw_graph(gc,0,color)
         title_color = Graphinity::fixnum_to_col(@parent.config.text_color)
      when 1 # anaglyphic black
         fill_block(gc,black,0,0,@old_xsize,@old_ysize)
         gc.function = Gdk::GC::OR
         draw_graph(gc,1,red)
         draw_graph(gc,-1,cyan)
         title_color = white
      when 2 # anaglyphic white
         fill_block(gc,white,0,0,@old_xsize,@old_ysize)
         gc.function = Gdk::GC::AND
         draw_graph(gc,1,cyan)
         draw_graph(gc,-1,red)
         title_color = black
      end
      # the default operator
      gc.function = Gdk::GC::COPY
      if(@draw_border)
         color = Graphinity::fixnum_to_col(@parent.config.border_color)
         color = choose_anaglyph_color(color,black,white)
         case @parent.config.anaglyph_mode
         when 1
            color = white
         when 2
            color = black
         end
         gc.rgb_fg_color = color
         @pixmap.draw_rectangle(gc,false,0,0,@old_xsize-1,@old_ysize-1)
      end
      if(@chart_title.size > 0)
         color = Graphinity::fixnum_to_col(@parent.config.text_color)
         color = choose_anaglyph_color(color,black,white)
         gc.rgb_fg_color = color
         x = (@old_xsize - @chart_title.size * @title_char_width) / 2.0
         y = @internal_margin
         draw_text(@chart_title,@gc_text,x,y,@title_font,color)
      end
      # copy to display
      @parent.graphic_pane.window.draw_drawable(gc,@pixmap,0,0,0,0,@old_xsize,@old_ysize)
   end
end # class GraphEngine3d

class GraphEngine2d < GraphEngine

   def initialize(app)
      super(app)
   end

   def format_index_num(n)
      return sprintf("%g",n)
   end

   def draw_grid(gc)
      gridCol = Graphinity::fixnum_to_col(@parent.config.grid_color)
      if(@draw_border)
         borderColor = Graphinity::fixnum_to_col(@parent.config.border_color)
         gc.rgb_fg_color = borderColor;
         @pixmap.draw_rectangle(gc,false,0,0,@old_xsize-1,@old_ysize-1)
      end
      gc.rgb_fg_color = gridCol
      y = 0
      while (y <= @y_grid_steps)
         gy = ntrp(0,@y_grid_steps.to_f,@draw_ya,@draw_yb,y)
         draw_line(gc,@draw_xa,gy,@draw_xb,gy)

         if(@show_y_nums)
            sv = ntrp(0,@y_grid_steps.to_f,@ya2d,@yb2d,y)
            ss = format_index_num(sv)
            right_just = ss.size * @normal_char_width + @internal_margin
            draw_text(ss,@gc_text,@draw_xa - right_just,gy-@normal_char_height/2,@normal_font,@number_color)
         end
         y += 1
      end

      x = 0
      while (x <= @x_grid_steps)
         gx = ntrp(0,@x_grid_steps.to_f,@draw_xa,@draw_xb,x)
         draw_line(gc,gx,@draw_ya,gx,@draw_yb)
         if(@show_x_nums)
            sv = ntrp(0,@x_grid_steps.to_f,@xa2d,@xb2d,x)
            ss = format_index_num(sv)
            center_bias = ss.size * @normal_char_width / 2
            draw_text(ss,@gc_text,gx-center_bias,@draw_ya+@normal_char_height/2,@normal_font,@number_color)
         end
         x += 1
      end

      if(@show_x_nums && @x_axis_label.size > 0)
         draw_text(@x_axis_label,@gc_text,@draw_xb+@internal_margin,@draw_ya+@normal_char_height/2,@normal_font)
      end
      if(@show_y_nums && @y_axis_label.size > 0)
         draw_text(@y_axis_label,@gc_text,@draw_xa-@internal_margin-@y_axis_label.size * @normal_char_width,@draw_yb-@internal_margin-@title_char_height,@normal_font)
      end
      if(@chart_title.size > 0)
         x = draw_x = (((@draw_xb - @draw_xa) - @chart_title.size * @title_char_width) / 2.0) + @draw_xa
         y = @draw_yb-@internal_margin-@title_char_height
         draw_text(@chart_title,@gc_text,x,y,@title_font)
      end

   end

   def draw_graph(gc)
      first = true
      ogx=ogy=0
      plotCol = Graphinity::fixnum_to_col(@parent.config.plot_color)
      gc.rgb_fg_color= plotCol
      steps = @plot_steps_2d
      steps = (steps < 8.0)?8.0:(steps)
      if(steps > 0 && defined? @gproc)
         xi = 0
         while(xi <= steps && !@suspend_equation)
            x = ntrp(0,steps,@xa2d,@xb2d,xi)
            y = 0
            begin
               y = @gproc.call(x,y,@control_var_a,@control_var_b,@control_var_c)
            rescue Exception => err
               if !@suspend_equation
                  s = err.to_s.sub(/(.*)for.*/,"\\1")
                  error_dialog("Execution",s)
               end
               y = 0
               @suspend_equation = true
            end
            begin
               gx = ntrp(@xa2d,@xb2d,@draw_xa,@draw_xb,x)
               gy = ntrp(@ya2d,@yb2d,@draw_ya,@draw_yb,y)
               unless first
                  if((inside(ogx,@draw_xa,@draw_xb) \
                  && inside(gx,@draw_xa,@draw_xb)) \
                  || (inside(ogy,@draw_yb,@draw_ya) \
                  && inside(gy,@draw_yb,@draw_ya)))
                     draw_line(gc,ogx,ogy,gx,gy)
                  end
               end
            rescue
               # errors converting huge floats to integers
            end
            ogx = gx;ogy = gy;
            first = false
            xi += 1
         end
         mx = @parent.mouse_x_pos
         my = @parent.mouse_y_pos
         if(mx) # if mouse is in play
            if (mx >= 0 && mx < @old_xsize &&
               my >= 0 && my < @old_ysize)
               x = ntrp(@draw_xa,@draw_xb,@xa2d,@xb2d,mx.to_f)
               posx = ntrp(@draw_xa,@draw_xb,0.0,1.0,mx.to_f)
               y = 0
               begin
                  y = @gproc.call(x,y,@control_var_a,@control_var_b,@control_var_c)
               rescue
                  y = 0
               end
               gy = ntrp(@ya2d,@yb2d,@draw_ya,@draw_yb,y)
               posy = ntrp(@ya2d,@yb2d,0,1,y)
               lineCol = Graphinity::fixnum_to_col(@parent.config.text_color)
               gc.rgb_fg_color= lineCol
               draw_line(gc,mx,@draw_ya,mx,@draw_yb)
               draw_line(gc,@draw_xa,gy,@draw_xb,gy)
               s = "Data: x = #{sprintf("%g",x)}, y = #{sprintf("%g",y)}"
               offset = @normal_char_height/2
               w = s.size * @normal_char_width
               h = @normal_char_height
               # position text in a suitable quadrant
               dispx = (posx < 0.5)?mx+offset:mx-w-offset
               dispy = (posy < 0.5)?gy-offset-h:gy-offset+h
               draw_text(s,@gc_text,dispx,dispy,@normal_font)
            end
         end
      end
   end

   def draw_image()
      set_sizes
      @pango_context = Gdk::Pango.context
      return unless @parent.graphic_pane.window
      # use double-buffering
      @pixmap = Gdk::Pixmap.new(@parent.graphic_pane.window,@old_xsize,@old_ysize,-1)
      gc = Gdk::GC.new(@pixmap)
      gc.set_line_attributes(@line_thickness,Gdk::GC::LineStyle::SOLID,Gdk::GC::CapStyle::ROUND,Gdk::GC::JoinStyle::MITER)
      @gc_text = Gdk::GC.new(@pixmap)
      @text_color = Graphinity::fixnum_to_col(@parent.config.text_color)
      @number_color = Graphinity::fixnum_to_col(@parent.config.number_color)
      @gc_text.rgb_fg_color = Graphinity::fixnum_to_col(@parent.config.text_color)
      # figure out margins
      @chart_title.gsub!(/\?/,@parent.equation2DLineEdit.text)
      @x_axis_label = @parent.xLabelLineEdit.text.strip
      @y_axis_label = @parent.yLabelLineEdit.text.strip
      @show_x_nums = @parent.xIndexCheckBox.active?
      @show_y_nums = @parent.yIndexCheckBox.active?
      # compute main title margin
      if(@chart_title.size > 0)
         @main_title_margin = @internal_margin + @title_char_height
      else
         @main_title_margin = 0
      end
      # compute Y axis title margin
      if(@y_axis_label.size > 0)
         @y_axis_label_margin = @internal_margin + @normal_char_height
         @title_left_margin = @normal_char_width * @y_axis_label.size/2
      else
         @y_axis_label_margin = 0
         @title_left_margin = 0
      end
      @top_margin = max(@main_title_margin,@y_axis_label_margin)

      # compute X axis title margin
      if(@x_axis_label.size > 0)
         @x_axis_label_margin = @internal_margin + @normal_char_width * @x_axis_label.size
      else
         @x_axis_label_margin = 0
      end

      # Noooo! Pleaseeee!
      if(@x_grid_steps == 0 || @y_grid_steps == 0)
         @x_grid_steps = 10
         @y_grid_steps = 10
         @parent.xGridStepsLineEdit.text = @x_grid_steps.to_s
         @parent.yGridStepsLineEdit.text = @y_grid_steps.to_s
      end

      # compute left margin
      s1 = format_index_num(@xa2d).size
      if(@show_y_nums)
         # must avoid cases of unexpectedly wide numbers
         sa = []
         0.upto(@y_grid_steps) do |y|
            gy = ntrp(0,@y_grid_steps,@ya2d,@yb2d,y.to_f)
            s = format_index_num(gy)
            sa << s.size
         end
         sc = sa.max
         @num_left_margin = @internal_margin + sc * @normal_char_width
      elsif(@show_x_nums)
         @num_left_margin = @internal_margin + s1 * @normal_char_width
      else
         @num_left_margin = 0
      end
      # compute bottom_margin
      if(@show_x_nums)
         @bottom_margin = @normal_char_height + @internal_margin
      elsif(@show_y_nums)
         @bottom_margin = @normal_char_height/2 + @internal_margin
      else
         @bottom_margin = 0
      end

      @left_margin = max(@title_left_margin,@num_left_margin)

      # compute number right margin
      if(@show_x_nums)
         @num_right_margin = @internal_margin + format_index_num(@xb2d).size * @normal_char_width/2
      else
         @num_right_margin = 0
      end

      # compute text right margin
      if(@x_axis_label.size > 0)
         @title_right_margin = @internal_margin + @normal_char_width * @x_axis_label.size
      else
         @title_right_margin = 0
      end
      @right_margin = max(@num_right_margin,@title_right_margin)

      # assign the values
      @draw_xa = @internal_margin + @left_margin
      @draw_xb = @old_xsize - @right_margin - @internal_margin
      @draw_ya = @old_ysize - @bottom_margin - @internal_margin
      @draw_yb = @internal_margin + @top_margin
      gc.function = Gdk::GC::COPY
      fill_block(gc,@bg_color,0,0,@old_xsize,@old_ysize)
      draw_grid(gc)
      draw_graph(gc)
      # copy to display
      @parent.graphic_pane.window.draw_drawable(gc,@pixmap,0,0,0,0,@old_xsize,@old_ysize)
   end
end # class GraphEngine2d

# Main program
if __FILE__ == $0
   # Set values as your own application.
   PROG_PATH = "graphinityui.glade"
   PROG_NAME = "Graphinity"
   Graphinity.new(PROG_PATH, nil, PROG_NAME)
   Gtk.main
end