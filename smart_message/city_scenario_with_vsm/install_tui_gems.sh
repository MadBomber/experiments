#!/bin/bash
# install_tui_gems.sh - Install gems needed for TUI interface

echo "Installing TTY gems for beautiful terminal interface..."

gem install tty-prompt tty-box tty-screen tty-cursor tty-spinner

echo "TUI gems installed successfully!"
echo "You can now run ./tip_line.rb with the enhanced terminal interface."