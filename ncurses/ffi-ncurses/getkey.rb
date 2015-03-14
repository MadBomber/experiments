#!/usr/bin/env ruby
# encoding: UTF-8
#
# Note: terminal set to:
#     LANG=en_GB.utf8
#
# Sean O'Halpin, 2010-08-29

require 'ffi-ncurses'

include FFI::NCurses

$APP_DEBUG = ARGV.delete("--debug")

def log(*a)
  if $APP_DEBUG
    File.open("log.txt", "ab") do |file|
      file.puts a.inspect
    end
  end
end

def line(row, txt = nil)
  move row, 2
  if txt
    addstr(txt)
  end
end

def column(col, txt = nil)
  y, x = getyx(stdscr)
  move y, col
  if txt
    addstr(txt)
  end
end

$APP_USE_WIDECHARS = ARGV.delete("--no-widechars") ? false : true
def use_widechars?
  $APP_USE_WIDECHARS
end

@last_keys = []

def getkey(win, input_buffer)
  if use_widechars?
    log :wget_wch
    # Note: 1.8.x stalls in this function without setlocale(LC_ALL, "")
    rv = FFI::NCurses.wget_wch(win, input_buffer)
    log :rv, rv
    ch = input_buffer.read_int # assumes wint_t is an int (which in all cases I've seen it is...)
    log :ch, ch

    # flag if a function key code
    if rv == KEY_CODE_YES
      fkey = true
    else
      fkey = false
    end
  else
    # use 8-bit input - won't handle Unicode properly
    log :wgetch
    ch = FFI::NCurses.wgetch(win)
    if (KEY_CODE_YES..KEY_MAX).include?(ch)
      fkey = true
    else
      fkey = false
    end
  end
  # convert char code to UTF-8 string
  char = [ch].pack("U")
  log :getkey, :fkey, fkey, :ch, ch, :char, char
  @last_keys.unshift(ch)
  while @last_keys.size > 10
    @last_keys.pop
  end
  [fkey, ch, char]
end

def header
  clear
  line 1, "Press any key to display codes in various interpretations"
  line 2, "Press Ctrl-Q to quit."
  line 3, "widechar input %s. Press w to toggle" % [use_widechars? ? "on" : "off"]
  line 4, "keypad %s. Press k to toggle" % [@keypad_toggle ? "on" : "off"]
  line 5, "meta %s. Press m to toggle (only makes a difference in non-widechar mode)" % [@meta_toggle ? "on" : "off"]
  line 6, "meta works only on terminal emulators that allow 8-bit input - use xterm to see effect"
end

begin
  # initialize screen and input params
  win = initscr
  curs_set 0
  raw
  set_escdelay(1000) if respond_to?(:set_escdelay)
  # turn on meta - ncurses default = true - but here to remind me that you can
  # detect Alt keys using keyname (e.g. Alt-q == "M-q")
  @meta_toggle = ARGV.delete("--no-meta") ? false : true
  @keypad_toggle = ARGV.delete("--no-keypad") ? false : true
  meta(stdscr, @meta_toggle)
  keypad stdscr, @keypad_toggle
  noecho

  # initialize colour
  start_color

  # Define a couple of custom keys. The easiest way to find out the sequences is to type
  #
  #   $ cat -v
  #
  # at the command line then press the key combination you want.
  #
  # Note that these key definitions may not be portable.
  define_key("\e[1;5C", KEY_MAX - 1) # C-Right
  define_key("\e[1;5D", KEY_MAX - 2) # C-Left
  define_key("\e[1;5A", KEY_MAX - 3) # C-Up
  define_key("\e[1;5B", KEY_MAX - 3) # C-Down


  # set up colour pairs
  #             Background      Foreground
  init_pair(0,  Color::BLACK,   Color::BLACK)
  init_pair(1,  Color::RED,     Color::BLACK)
  init_pair(2,  Color::GREEN,   Color::BLACK)
  init_pair(3,  Color::YELLOW,  Color::BLACK)
  init_pair(4,  Color::BLUE,    Color::BLACK)
  init_pair(5,  Color::MAGENTA, Color::BLACK)
  init_pair(6,  Color::CYAN,    Color::BLACK)
  init_pair(7,  Color::WHITE,   Color::BLACK)

  init_pair(8,  Color::BLACK,   Color::BLACK)
  init_pair(9,  Color::BLACK,   Color::RED)
  init_pair(10, Color::BLACK,   Color::GREEN)
  init_pair(11, Color::BLACK,   Color::YELLOW)
  init_pair(12, Color::BLACK,   Color::BLUE)
  init_pair(13, Color::BLACK,   Color::MAGENTA)
  init_pair(14, Color::BLACK,   Color::CYAN)
  init_pair(15, Color::BLACK,   Color::WHITE)

  # set up input buffer
  buffer = FFI::Buffer.new(FFI::NCurses.find_type(:wint_t))
  log :buffer_size, buffer.size, FFI.find_type(:int).size

  # set up output wide char struct
  cchar = WinStruct::CCharT.new
  cchar[:attr] = 0

  char_col = 55

  header
  row = 8
  loop do
    # read a key
    fkey, ch, char = getkey(win, buffer)
    break if ch == KEY_CTRL_Q

    case char
    when "k"
      @keypad_toggle = !@keypad_toggle
      keypad stdscr, @keypad_toggle # NB. win arg ignored
    when "m"
      @meta_toggle = !@meta_toggle
      meta stdscr, @meta_toggle # NB. win arg ignored
    when "w"
      $APP_USE_WIDECHARS = !$APP_USE_WIDECHARS
    end

    header
    mvwaddstr(win, 20, 2, @last_keys.inspect)

    attr_on(A_BOLD, nil) if fkey
    line row + 1, "#{fkey ? "Function" : "Normal"} key"
    attr_off(A_BOLD, nil) if fkey

    line row + 2, "keycode:"
    column char_col, "#{"0x%04x" % ch} (#{ch}) "

    line row + 3, "keyname: "
    column char_col, "[#{keyname(ch)}]"

    line row + 4, "key_name: "
    column char_col, "[#{key_name(ch)}]"

    line row + 5, "output as raw keycode using waddch (non-widechar):"
    column char_col, "["
    waddch win, char[0].ord
    addstr "]"

    line row + 6, "output as UTF-8 string using waddstr (non-widechar):"
    column char_col, "["
    attr_on(COLOR_PAIR(5) | A_BOLD, nil)
    waddstr win, char
    attr_off(COLOR_PAIR(5) | A_BOLD, nil)
    addstr "]"

    line row + 7, "output Unicode character using wadd_wch (widechar):"
    cchar[:attr] = COLOR_PAIR(6) | A_BOLD
    cchar[:chars][0] = ch # ch == Unicode codepoint
    column char_col, "["
    wadd_wch win, cchar
    addstr "]"

    refresh
  end
rescue => saved_exception
ensure
  flushinp
  endwin
end
if saved_exception
  raise saved_exception
end
