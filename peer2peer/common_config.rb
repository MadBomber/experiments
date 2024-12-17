# common_config.rb

require 'amazing_print'
require 'debug_me'
include DebugMe

AGENTS = {
  one:   { ip: '127.0.0.1', port: 3001 },
  two:   { ip: '127.0.0.1', port: 3002 },
  three: { ip: '127.0.0.1', port: 3003 }
}

module Agent99
  # ...
end
