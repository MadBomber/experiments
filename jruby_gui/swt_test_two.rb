#!/usr/bin/env ruby
###################################################
###
##  File: swt_test_two.rb
##  Desc: Simple example of a Java UI using Jruby
#

require 'java'

module SWTTest

  Display   = org.eclipse.swt.widgets.Display
  Shell     = org.eclipse.swt.widgets.Shell
  RowLayout = org.eclipse.swt.layout.RowLayout
  Label     = org.eclipse.swt.widgets.Label
  Button    = org.eclipse.swt.widgets.Button

  Display.app_name = "Ruby SWT Test"

  display   = Display.new
  shell     = Shell.new(d) do |sh|
    sh.set_size(450, 200)
    sh.text     = "Ruby SWT Test"
    sh.layout   = RowLayout.new do |layout|
      layout.wrap = true
    end

    Label.new(shell, SWT::CENTER).text = "Ruby SWT Test"
    Button.new(shell, SWT::PUSH).text = "Test Button 1"

  end

  shell.pack
  shell.open

  while (!shell.isDisposed) do
    display.sleep unless display.readAndDispatch
  end

  display.dispose

end # end of module SWTTest

