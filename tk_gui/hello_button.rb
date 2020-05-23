#!/usr/bin/env ruby
# experiments/tk_gui/hello_button.rb


require "tk"

button = TkButton.new {
   text 'Hello World!'
   pack
}
button.configure('activebackground', 'blue')
Tk.mainloop
