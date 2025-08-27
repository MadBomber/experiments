#!/usr/bin/env ruby

require 'tty-box'
require 'tty-color'
require 'tty-cursor'
require 'tty-prompt'
require 'tty-reader'
require 'tty-screen'
require 'tty-table'
require 'pastel'
require 'io/console'

class TUIFramework
  attr_reader :cursor, :pastel, :screen_width, :screen_height
  
  def initialize
    @cursor = TTY::Cursor
    @pastel = Pastel.new
    @screen_width = TTY::Screen.width
    @screen_height = TTY::Screen.height
    @panes = []
    @dialogs = []
    clear_screen
  end
  
  def clear_screen
    print @cursor.clear_screen
    print @cursor.move_to(0, 0)
  end
  
  def refresh
    clear_screen
    @panes.each { |pane| render_pane(pane) }
    @dialogs.each { |dialog| render_dialog(dialog) }
  end
  
  class Pane
    attr_accessor :x, :y, :width, :height, :title, :content, :bg_color, :fg_color, :border_style
    
    def initialize(x:, y:, width:, height:, title: '', content: '', bg_color: nil, fg_color: :white, border_style: :light)
      @x = x
      @y = y
      @width = width
      @height = height
      @title = title
      @content = content
      @bg_color = bg_color
      @fg_color = fg_color
      @border_style = border_style
    end
  end
  
  class Dialog
    attr_accessor :title, :message, :type, :buttons, :width, :height
    
    def initialize(title:, message:, type: :info, buttons: ['OK'], width: 40, height: 10)
      @title = title
      @message = message
      @type = type
      @buttons = buttons
      @width = width
      @height = height
    end
  end
  
  class Form
    attr_reader :fields, :current_field
    
    def initialize(x:, y:, width:, title: 'Form')
      @x = x
      @y = y
      @width = width
      @title = title
      @fields = []
      @current_field = 0
    end
    
    def add_field(label:, name:, type: :text, default: '', required: false)
      @fields << {
        label: label,
        name: name,
        type: type,
        value: default,
        required: required
      }
    end
    
    def next_field
      @current_field = (@current_field + 1) % @fields.length
    end
    
    def previous_field
      @current_field = (@current_field - 1) % @fields.length
    end
    
    def get_values
      Hash[@fields.map { |f| [f[:name], f[:value]] }]
    end
  end
  
  def create_pane(x:, y:, width:, height:, **options)
    pane = Pane.new(x: x, y: y, width: width, height: height, **options)
    @panes << pane
    pane
  end
  
  def remove_pane(pane)
    @panes.delete(pane)
  end
  
  def render_pane(pane)
    box_options = {
      title: pane.title ? { top_left: " #{pane.title} " } : nil,
      border: pane.border_style,
      style: {
        fg: pane.fg_color,
        bg: pane.bg_color
      }
    }
    
    box = TTY::Box.frame(
      left: pane.x,
      top: pane.y,
      width: pane.width,
      height: pane.height,
      **box_options
    ) do
      pane.content
    end
    
    print box
  end
  
  def show_dialog(title:, message:, type: :info, buttons: ['OK'])
    dialog = Dialog.new(
      title: title,
      message: message,
      type: type,
      buttons: buttons
    )
    
    @dialogs << dialog
    refresh
    
    result = wait_for_dialog_input(dialog, buttons)
    
    @dialogs.delete(dialog)
    refresh
    
    result
  end
  
  def render_dialog(dialog)
    x = (@screen_width - dialog.width) / 2
    y = (@screen_height - dialog.height) / 2
    
    bg_color = case dialog.type
    when :error then :red
    when :warning then :yellow
    when :success then :green
    else :blue
    end
    
    box = TTY::Box.frame(
      left: x,
      top: y,
      width: dialog.width,
      height: dialog.height,
      title: { top_left: " #{dialog.title} " },
      border: :thick,
      style: {
        fg: :white,
        bg: bg_color
      }
    ) do
      "#{dialog.message}\n\n" + dialog.buttons.join('  ')
    end
    
    print box
  end
  
  def wait_for_dialog_input(dialog, buttons)
    reader = TTY::Reader.new
    selected = 0
    
    loop do
      x = (@screen_width - dialog.width) / 2
      y = (@screen_height - dialog.height) / 2 + dialog.height - 3
      
      buttons.each_with_index do |button, idx|
        print @cursor.move_to(x + 2 + (idx * 10), y)
        if idx == selected
          print @pastel.on_white.black(" #{button} ")
        else
          print " #{button} "
        end
      end
      
      key = reader.read_keypress
      
      case key
      when "\t", :right
        selected = (selected + 1) % buttons.length
      when :left
        selected = (selected - 1) % buttons.length
      when "\r"
        return buttons[selected]
      when "\e"
        return nil
      end
    end
  end
  
  def create_form(x:, y:, width:, title: 'Form')
    Form.new(x: x, y: y, width: width, title: title)
  end
  
  def show_form(form)
    reader = TTY::Reader.new
    
    render_form(form)
    
    loop do
      render_form_field(form, form.current_field)
      
      key = reader.read_keypress
      
      case key
      when "\t"
        form.next_field
      when "\e[Z"  # Shift-Tab
        form.previous_field
      when "\r"
        if validate_form(form)
          return form.get_values
        end
      when "\e"
        return nil
      else
        if key.is_a?(String) && key.length == 1
          field = form.fields[form.current_field]
          field[:value] += key
        elsif key == :backspace
          field = form.fields[form.current_field]
          field[:value] = field[:value][0...-1]
        end
      end
    end
  end
  
  def render_form(form)
    box = TTY::Box.frame(
      left: form.instance_variable_get(:@x),
      top: form.instance_variable_get(:@y),
      width: form.instance_variable_get(:@width),
      height: form.fields.length * 3 + 4,
      title: { top_left: " #{form.instance_variable_get(:@title)} " },
      border: :light
    )
    
    print box
    
    form.fields.each_with_index do |field, idx|
      render_form_field(form, idx)
    end
  end
  
  def render_form_field(form, field_index)
    x = form.instance_variable_get(:@x)
    y = form.instance_variable_get(:@y)
    
    field = form.fields[field_index]
    field_y = y + 2 + (field_index * 3)
    
    print @cursor.move_to(x + 2, field_y)
    
    if field[:required]
      print @pastel.red("#{field[:label]}:")
    else
      print @pastel.white("#{field[:label]}:")
    end
    
    print @cursor.move_to(x + 2, field_y + 1)
    
    if field_index == form.current_field
      print @pastel.on_blue.white(" #{field[:value].ljust(30)} ")
    else
      print @pastel.white("[ #{field[:value].ljust(28)} ]")
    end
  end
  
  def validate_form(form)
    form.fields.each do |field|
      if field[:required] && field[:value].strip.empty?
        show_dialog(
          title: 'Validation Error',
          message: "#{field[:label]} is required!",
          type: :error
        )
        return false
      end
    end
    true
  end
  
  def split_horizontal(top_height_percent: 50)
    top_height = (@screen_height * top_height_percent / 100).to_i
    
    top_pane = create_pane(
      x: 0,
      y: 0,
      width: @screen_width,
      height: top_height,
      title: 'Top Pane',
      bg_color: :blue
    )
    
    bottom_pane = create_pane(
      x: 0,
      y: top_height,
      width: @screen_width,
      height: @screen_height - top_height,
      title: 'Bottom Pane',
      bg_color: :green
    )
    
    [top_pane, bottom_pane]
  end
  
  def split_vertical(left_width_percent: 50)
    left_width = (@screen_width * left_width_percent / 100).to_i
    
    left_pane = create_pane(
      x: 0,
      y: 0,
      width: left_width,
      height: @screen_height,
      title: 'Left Pane',
      bg_color: :magenta
    )
    
    right_pane = create_pane(
      x: left_width,
      y: 0,
      width: @screen_width - left_width,
      height: @screen_height,
      title: 'Right Pane',
      bg_color: :cyan
    )
    
    [left_pane, right_pane]
  end
  
  def run_event_loop
    reader = TTY::Reader.new
    
    loop do
      key = reader.read_keypress
      
      case key
      when 'q', "\e"
        break
      when 'r'
        refresh
      end
      
      yield key if block_given?
    end
  end
end