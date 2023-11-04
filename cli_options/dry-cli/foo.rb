# .../foo.rb

require 'debug_me'
include DebugMe

$DEBUG_ME = true
DebugMeDefaultOptions[:skip2] = true

# Establish the application namespace
module Foo
	VERSION = '0.0.1-alpha'
end

