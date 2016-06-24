require 'SysVIPC'

require 'debug_me'
include DebugMe


# All IPC objects are identified by a key. SysVIPC includes a
# convenience function for mapping file names and integer IDs into a
# key:

key = SysVIPC.ftok(ARGV.shift, 0)

# Get (create if necessary) a message queue:

mq = SysVIPC::MessageQueue.new(key, SysVIPC::IPC_CREAT | 0600)

# Get (create if necessary) an 8192-byte shared memory region:

sh = SysVIPC::SharedMemory.new(key, 8192, SysVIPC::IPC_CREAT | 0660)
#
# Attach shared memory:

shmaddr = sh.attach

debug_me(tag: "worker:#{Process.pid}", header: false){[ :key, :mq, :sh, :shmaddr ]}

# Receive up to 100 bytes from the first message of type 0:
# NOTE: this will block until it has collected all of the message or
#       until 100 characters have been received.  I don't know what
#       tyoe == 0 does because it was type == 1 that was sent.
msg = mq.receive(0, 100)

debug_me(tag: "worker:#{Process.pid}", header: false){[ :msg ]}


until false
  rand(100_000)
end


=begin

my_pid = Process.pid.to_s

# NOTE: Lets monitor some shared memory.
#       The shared memory block is in a static location; but,
#       Ruby doesn't care about memory addresses.  THe GC can move
#       objects around all over the memory map.  This makes it much
#       harder in Ruby over a traditional 'C' approach using offsets
#       from an anchored position.  Wish there werw a way to
#       anchor a Ruby object to a specific address and make it
#       immune from GC.  Why would anyone want to do this?  Now-a-days
#       all the stuff for which we once had to access bare metal are
#       covered by SDK's API's and such.  Accessing memory is not
#       a "modern" requirement ... until its needed ... after all who
#       in their right mind would ever write a device driver in Ruby?
#       I mean besides me.

msg = []
until msg.first == my_pid && msg.last == 'quit'
  data = shmaddr.read(my_pid.size + ',quit'.size)
  debug_me(tag: "worker:#{Process.pid}", header: false){[ :data ]}
  msg = data.split(',')
end 

shmaddr.write('okay')

# Detach shared memory:

sh.detach(shmaddr)

debug_me(tag: "worker:#{Process.pid} ending")

=end

