#!/usr/bin/env ruby

require_relative 'tui_framework'
require 'tty-prompt'
require 'tty-table'
require 'tty-progressbar'

class DemoApp
  def initialize
    @tui = TUIFramework.new
    @data = []
  end
  
  def run
    show_welcome
    main_menu
  end
  
  private
  
  def show_welcome
    @tui.clear_screen
    
    welcome_pane = @tui.create_pane(
      x: 10,
      y: 2,
      width: 60,
      height: 10,
      title: 'Welcome to TUI Demo',
      content: "This demo showcases:\n" +
               "• Popup dialogs\n" +
               "• Panes with colored backgrounds\n" +
               "• Form fields with TAB navigation\n" +
               "• Tables and data display\n" +
               "\nPress any key to continue...",
      bg_color: :blue,
      fg_color: :white,
      border_style: :thick
    )
    
    @tui.refresh
    $stdin.getch
    @tui.remove_pane(welcome_pane)
  end
  
  def main_menu
    loop do
      @tui.clear_screen
      
      menu_pane = @tui.create_pane(
        x: 5,
        y: 2,
        width: 50,
        height: 15,
        title: 'Main Menu',
        content: "Choose an option:\n\n" +
                 "1. Show Dialog Examples\n" +
                 "2. Show Form Example\n" +
                 "3. Show Pane Layouts\n" +
                 "4. Show Data Table\n" +
                 "5. Interactive Form Demo\n" +
                 "6. Progress Bar Demo\n" +
                 "\nQ. Quit\n\n" +
                 "Enter your choice: ",
        bg_color: :cyan,
        fg_color: :black,
        border_style: :thick
      )
      
      @tui.refresh
      
      choice = $stdin.getch.downcase
      @tui.remove_pane(menu_pane)
      
      case choice
      when '1'
        show_dialog_examples
      when '2'
        show_form_example
      when '3'
        show_pane_layouts
      when '4'
        show_data_table
      when '5'
        interactive_form_demo
      when '6'
        progress_bar_demo
      when 'q'
        @tui.show_dialog(
          title: 'Goodbye',
          message: 'Thanks for using the TUI Demo!',
          type: :success,
          buttons: ['OK']
        )
        break
      end
    end
    
    @tui.clear_screen
  end
  
  def show_dialog_examples
    @tui.show_dialog(
      title: 'Information',
      message: 'This is an info dialog.\nIt has multiple lines.\nPress TAB to switch buttons.',
      type: :info,
      buttons: ['OK', 'Cancel']
    )
    
    @tui.show_dialog(
      title: 'Warning',
      message: 'This is a warning dialog!\nSomething might be wrong.',
      type: :warning,
      buttons: ['Proceed', 'Abort']
    )
    
    @tui.show_dialog(
      title: 'Error',
      message: 'This is an error dialog!\nSomething went wrong!',
      type: :error,
      buttons: ['Retry', 'Cancel']
    )
    
    @tui.show_dialog(
      title: 'Success',
      message: 'Operation completed successfully!',
      type: :success,
      buttons: ['Great!']
    )
  end
  
  def show_form_example
    @tui.clear_screen
    
    info_pane = @tui.create_pane(
      x: 2,
      y: 1,
      width: 76,
      height: 5,
      title: 'Form Instructions',
      content: "Use TAB to move between fields, ENTER to submit, ESC to cancel",
      bg_color: :yellow,
      fg_color: :black
    )
    
    form = @tui.create_form(x: 10, y: 7, width: 60, title: 'Sample Registration Form')
    form.add_field(label: 'First Name', name: :first_name, required: true)
    form.add_field(label: 'Last Name', name: :last_name, required: true)
    form.add_field(label: 'Email', name: :email, type: :email, required: true)
    form.add_field(label: 'Phone', name: :phone, type: :text, required: false)
    form.add_field(label: 'Comments', name: :comments, type: :text, required: false)
    
    @tui.refresh
    
    result = @tui.show_form(form)
    
    @tui.remove_pane(info_pane)
    
    if result
      @data << result
      @tui.show_dialog(
        title: 'Form Submitted',
        message: "Data saved:\n#{result.map { |k,v| "#{k}: #{v}" }.join("\n")}",
        type: :success
      )
    else
      @tui.show_dialog(
        title: 'Form Cancelled',
        message: 'No data was saved.',
        type: :warning
      )
    end
  end
  
  def show_pane_layouts
    @tui.clear_screen
    
    @tui.show_dialog(
      title: 'Pane Layouts',
      message: 'Showing horizontal split layout...',
      type: :info
    )
    
    top_pane, bottom_pane = @tui.split_horizontal(top_height_percent: 60)
    top_pane.content = "This is the top pane\nIt takes 60% of the screen height"
    bottom_pane.content = "This is the bottom pane\nIt takes 40% of the screen height"
    
    @tui.refresh
    sleep(3)
    
    @tui.remove_pane(top_pane)
    @tui.remove_pane(bottom_pane)
    
    @tui.show_dialog(
      title: 'Pane Layouts',
      message: 'Showing vertical split layout...',
      type: :info
    )
    
    left_pane, right_pane = @tui.split_vertical(left_width_percent: 30)
    left_pane.content = "Left pane\n30% width"
    right_pane.content = "Right pane - 70% width\nThis pane has more space for content"
    
    @tui.refresh
    sleep(3)
    
    @tui.remove_pane(left_pane)
    @tui.remove_pane(right_pane)
    
    @tui.clear_screen
    
    @tui.show_dialog(
      title: 'Pane Layouts',
      message: 'Showing complex layout...',
      type: :info
    )
    
    pane1 = @tui.create_pane(x: 1, y: 1, width: 40, height: 10, 
                             title: 'Red Pane', bg_color: :red, content: 'Content 1')
    pane2 = @tui.create_pane(x: 42, y: 1, width: 37, height: 10, 
                             title: 'Green Pane', bg_color: :green, content: 'Content 2')
    pane3 = @tui.create_pane(x: 1, y: 11, width: 78, height: 10, 
                             title: 'Blue Pane', bg_color: :blue, content: 'Wide content pane')
    
    @tui.refresh
    sleep(3)
    
    @tui.remove_pane(pane1)
    @tui.remove_pane(pane2)
    @tui.remove_pane(pane3)
  end
  
  def show_data_table
    @tui.clear_screen
    
    if @data.empty?
      @tui.show_dialog(
        title: 'No Data',
        message: 'No data available. Please fill out a form first.',
        type: :warning
      )
      return
    end
    
    headers = @data.first.keys.map(&:to_s).map(&:capitalize)
    rows = @data.map(&:values)
    
    table = TTY::Table.new(headers, rows)
    rendered_table = table.render(:unicode, padding: [0, 1])
    
    table_pane = @tui.create_pane(
      x: 2,
      y: 2,
      width: 76,
      height: 15,
      title: 'Data Table',
      content: rendered_table,
      bg_color: :black,
      fg_color: :white
    )
    
    @tui.refresh
    
    @tui.show_dialog(
      title: 'Table View',
      message: 'Press OK to return to menu',
      type: :info
    )
    
    @tui.remove_pane(table_pane)
  end
  
  def interactive_form_demo
    @tui.clear_screen
    
    title_pane = @tui.create_pane(
      x: 5,
      y: 1,
      width: 70,
      height: 4,
      title: 'Interactive Form Demo',
      content: 'Complete the form below using TAB to navigate',
      bg_color: :magenta,
      fg_color: :white
    )
    
    # Create a form within a pane
    form_pane = @tui.create_pane(
      x: 5,
      y: 5,
      width: 70,
      height: 20,
      title: 'User Profile Form',
      bg_color: :black,
      fg_color: :white,
      border_style: :thick
    )
    
    @tui.refresh
    
    # Use the framework's form instead of TTY::Prompt
    form = @tui.create_form(x: 7, y: 7, width: 66, title: 'User Information')
    form.add_field(label: 'Name', name: :name, required: true)
    form.add_field(label: 'Email', name: :email, required: true)
    form.add_field(label: 'Age', name: :age, required: false)
    form.add_field(label: 'City', name: :city, required: false)
    form.add_field(label: 'Language', name: :language, required: false, default: 'Ruby')
    form.add_field(label: 'Experience (years)', name: :experience, required: false)
    
    result = @tui.show_form(form)
    
    @tui.remove_pane(title_pane)
    @tui.remove_pane(form_pane)
    
    if result
      @tui.show_dialog(
        title: 'Form Data Collected',
        message: result.map { |k,v| "#{k}: #{v}" }.join("\n"),
        type: :success
      )
    else
      @tui.show_dialog(
        title: 'Form Cancelled',
        message: 'No data was collected.',
        type: :warning
      )
    end
  end
  
  def progress_bar_demo
    @tui.clear_screen
    
    title_pane = @tui.create_pane(
      x: 10,
      y: 2,
      width: 60,
      height: 4,
      title: 'Progress Bar Demo',
      content: 'Simulating a long-running process...',
      bg_color: :blue,
      fg_color: :white
    )
    
    progress_pane = @tui.create_pane(
      x: 10,
      y: 6,
      width: 60,
      height: 8,
      title: 'Processing',
      content: '',
      bg_color: :black,
      fg_color: :green,
      border_style: :thick
    )
    
    @tui.refresh
    
    # Simulate progress within the pane
    100.times do |i|
      percent = i + 1
      bar_width = 50
      filled = (bar_width * percent / 100).to_i
      bar = '█' * filled + '░' * (bar_width - filled)
      
      progress_content = "\n  Progress: #{percent}%\n" +
                        "\n  [#{bar}]\n" +
                        "\n  Processing item #{percent} of 100..."
      
      progress_pane.content = progress_content
      @tui.refresh
      
      sleep(0.02)
    end
    
    progress_pane.content = "\n  Progress: 100%\n" +
                           "\n  [#{'█' * 50}]\n" +
                           "\n  ✓ Processing complete!"
    progress_pane.fg_color = :green
    @tui.refresh
    
    sleep(1)
    
    @tui.remove_pane(title_pane)
    @tui.remove_pane(progress_pane)
    
    @tui.show_dialog(
      title: 'Complete',
      message: 'Progress bar demo completed successfully!',
      type: :success
    )
  end
end

if __FILE__ == $0
  app = DemoApp.new
  app.run
end