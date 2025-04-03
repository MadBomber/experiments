
require "lockfile"
require "thread"
m = Mutex.new
l = Lockfile.new('app')
m.synchronize{
  l.lock{
    call(io)
  }
}
