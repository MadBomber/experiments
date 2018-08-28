# TODO: Write documentation for `SpinnerTest`

require "spinner"

Spinner::Charset.values.each do |chars|
  sp = Spin.new(0.1, chars)
  sp.start
  sleep 2
  sp.stop
end
