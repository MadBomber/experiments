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

import one.just
include   two.just
require       three.just
with            four.just

# where did those come from?
@what: one two three four five six
  echo "what?"
