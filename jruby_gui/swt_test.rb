#!/usr/bin/env ruby
###################################################
###
##  File: swt_test.rb
##  Desc: Simple example of a Java UI using Jruby
#

require 'java'

module SWTTest

  include_package 'org.eclipse.swt'
  include_package 'org.eclipse.swt.layout'
  include_package 'org.eclipse.swt.widgets'

  Display.setAppName "Ruby SWT Test"

  display = Display.new
  shell = Shell.new display
  shell.setSize(450, 200)

  layout = RowLayout.new
  layout.wrap = true

  shell.setLayout layout
  shell.setText "Ruby SWT Test"

  label = Label.new(shell, SWT::CENTER)
  label.setText "Ruby SWT Test"

  Button.new(shell, SWT::PUSH).setText("Test Button 1")

  shell.pack
  shell.open

  while (!shell.isDisposed) do
    display.sleep unless display.readAndDispatch
  end

  display.dispose

end
