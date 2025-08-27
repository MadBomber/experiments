# TUI Framework

A comprehensive Terminal User Interface framework built with Ruby and TTY gems that provides classic terminal UI components similar to old-school text-based interfaces.

## Features

- **Popup Dialogs** - Info, warning, error, and success dialogs with button navigation
- **Colored Panes** - Create panes with different background colors and border styles
- **Form Fields** - TAB-navigable forms with validation support
- **Window Management** - Split screens horizontally/vertically, create complex layouts
- **Data Tables** - Display structured data in formatted tables
- **Progress Bars** - Show progress for long-running operations

## Files

- `tui_framework.rb` - Core framework with all TUI components
- `demo_app.rb` - Interactive demonstration of all features
- `tty_gems.txt` - List of installed TTY gems

## Usage

### Running the Demo

```bash
./demo_app.rb
```

The demo provides an interactive menu to explore all features:
1. Dialog examples (different types and colors)
2. Form with TAB navigation
3. Various pane layout demonstrations
4. Data table display
5. Interactive form using TTY::Prompt
6. Progress bar animation

### Using the Framework

```ruby
require_relative 'tui_framework'

# Initialize the framework
tui = TUIFramework.new

# Create a colored pane
pane = tui.create_pane(
  x: 10, y: 5,
  width: 40, height: 10,
  title: 'My Pane',
  content: 'Hello World!',
  bg_color: :blue,
  fg_color: :white
)

# Show a dialog
result = tui.show_dialog(
  title: 'Confirm',
  message: 'Are you sure?',
  type: :warning,
  buttons: ['Yes', 'No']
)

# Create a form
form = tui.create_form(x: 10, y: 5, width: 50, title: 'User Input')
form.add_field(label: 'Name', name: :name, required: true)
form.add_field(label: 'Email', name: :email, required: true)

# Display and process the form
data = tui.show_form(form)
```

## Navigation

- **TAB** - Move forward between form fields or dialog buttons
- **Shift+TAB** - Move backward between fields
- **ENTER** - Submit forms or select buttons
- **ESC** - Cancel dialogs or forms
- **Q** - Quit (in demo app)

## Requirements

All required TTY gems are listed in `tty_gems.txt`. Key dependencies:
- tty-box (frames and boxes)
- tty-color (color detection)
- tty-cursor (cursor control)
- tty-prompt (interactive prompts)
- tty-reader (keyboard input)
- tty-screen (screen dimensions)
- tty-table (formatted tables)
- pastel (color styling)