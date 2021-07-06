# experiments/just_playing/main.just


# see if the world is paying attention
@world: hello what
  echo "wprld"

# Usage
@help:
  echo
  just -l
  echo

# All sorts of interesting keywords
# from which to choose ...
#
# The parameter is a file name/path.  The path can be
# relative to the location of the main.just file OR it
# can be absolute (ie. starts with a / character).
# If the file does not exists and error message will
# be displayed to STDERR.

import one.just
include   two.just
require       three.just
with            four.just

# NOTE: no use of quotes around file name
require file with spaces.just


# where did those come from?
@what: one two three four five six worked
  echo "what?"

#############################################

alias cr  := compile
alias ins := install

# Compile the crystal version of justprep
compile:
  crystal build --no-debug --release -p -o bin/justprep justprep.cr


# Install the justprep executable in ~/bin
install: compile
  cp bin/justprep ~/bin
