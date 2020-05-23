#!/usr/bin/env ruby
# experiments/tk_gui/hello_world.rb

require 'tk'

root = TkRoot.new { title "Hello, World!" }
TkLabel.new(root) do
   text 'Hello, World!'
   pack { padx 15 ; pady 15; side 'left' }
end
Tk.mainloop


__END__

require 'tk'
hello = TkRoot.new {title "Hello World"}
Tk.mainloop

####################################

require 'tk'
hello = TkRoot.new do
  title "Hello World"
  # the min size of window
  minsize(400,400)
end
TkLabel.new(hello) do
  text 'Hello World'
  foreground 'red'
  pack { padx 15; pady 15; side 'left'}
end
Tk.mainloop

####################################

require 'tk'
TkButton.new do
  text "EXIT"
  command { exit }
  pack('side'=>'left', 'padx'=>10, 'pady'=>10)
end
Tk.mainloop


####################################

ruby -rtk -e "Tk.messageBox :message => 'Hello Ruby Tk'"

####################################

