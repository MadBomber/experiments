#!/usr/bin/env ruby
# -*- coding: utf-8; -*-
require 'ffi-ncurses'

include FFI::NCurses

def main
  begin
    initscr

    addstr("Upper left corner           "); addch(ACS_ULCORNER); addstr("\n");
    addstr("Lower left corner           "); addch(ACS_LLCORNER); addstr("\n");
    addstr("Lower right corner          "); addch(ACS_LRCORNER); addstr("\n");
    addstr("Tee pointing right          "); addch(ACS_LTEE); addstr("\n");
    addstr("Tee pointing left           "); addch(ACS_RTEE); addstr("\n");
    addstr("Tee pointing up             "); addch(ACS_BTEE); addstr("\n");
    addstr("Tee pointing down           "); addch(ACS_TTEE); addstr("\n");
    addstr("Horizontal line             "); addch(ACS_HLINE); addstr("\n");
    addstr("Vertical line               "); addch(ACS_VLINE); addstr("\n");
    addstr("Large Plus or cross over    "); addch(ACS_PLUS); addstr("\n");
    addstr("Scan Line 1                 "); addch(ACS_S1); addstr("\n");
    addstr("Scan Line 3                 "); addch(ACS_S3); addstr("\n");
    addstr("Scan Line 7                 "); addch(ACS_S7); addstr("\n");
    addstr("Scan Line 9                 "); addch(ACS_S9); addstr("\n");
    addstr("Diamond                     "); addch(ACS_DIAMOND); addstr("\n");
    addstr("Checker board (stipple)     "); addch(ACS_CKBOARD); addstr("\n");
    addstr("Degree Symbol               "); addch(ACS_DEGREE); addstr("\n");
    addstr("Plus/Minus Symbol           "); addch(ACS_PLMINUS); addstr("\n");
    addstr("Bullet                      "); addch(ACS_BULLET); addstr("\n");
    addstr("Arrow Pointing Left         "); addch(ACS_LARROW); addstr("\n");
    addstr("Arrow Pointing Right        "); addch(ACS_RARROW); addstr("\n");
    addstr("Arrow Pointing Down         "); addch(ACS_DARROW); addstr("\n");
    addstr("Arrow Pointing Up           "); addch(ACS_UARROW); addstr("\n");
    addstr("Board of squares            "); addch(ACS_BOARD); addstr("\n");
    addstr("Lantern Symbol              "); addch(ACS_LANTERN); addstr("\n");
    addstr("Solid Square Block          "); addch(ACS_BLOCK); addstr("\n");
    addstr("Less/Equal sign             "); addch(ACS_LEQUAL); addstr("\n");
    addstr("Greater/Equal sign          "); addch(ACS_GEQUAL); addstr("\n");
    addstr("Pi                          "); addch(ACS_PI); addstr("\n");
    addstr("Not equal                   "); addch(ACS_NEQUAL); addstr("\n");
    addstr("UK pound sign               "); addch(ACS_STERLING); addstr("\n");

    refresh
    getch
  rescue => e
    endwin
    raise
  ensure
    endwin
  end
end

main
