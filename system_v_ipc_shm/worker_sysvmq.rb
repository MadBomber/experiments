require 'sysvmq'

require 'debug_me'
include DebugMe

key = ARGV.shift.to_i

# Get (create if necessary) a message queue:

mq    = SysVMQ.new(key, 1024, SysVMQ::IPC_CREAT | 0666)

debug_me(tag: "worker:#{Process.pid}", header: false){[ :key, :mq ]}

count = 0
while mq.stats[:count] > 0
  msg = mq.receive.force_encoding("UTF-8")
  debug_me(tag: "worker:#{Process.pid}", header: false){[ :msg ]}
  count += 1
  sleep(rand(5))
end

  debug_me(tag: "worker:#{Process.pid} terminating", header: false){[ :count ]}
