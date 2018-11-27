# hardware_test.cr

require "hardware"

memory = Hardware::Memory.new
print "memory.used: "
puts memory.used # => 2731404

print "memory.percent.to_i: "
puts memory.percent.to_i # => 32

print "vpu "
cpu = Hardware::CPU.new

print "pid "
pid = Hardware::PID.new # Default is Process.pid

# print "app"
# app = Hardware::PID.new "firefox" # Take the first matching PID

puts
puts "Starting loop ..."

loop do
  sleep 1
  print "cpu.usage.to_i: "
  puts cpu.usage.to_i # => 17

  print "pid.cpu_usage: "
  puts pid.cpu_usage # => 1.5

  # print "app.cpu_usage.to_i: "
  # puts app.cpu_usage.to_i # => 4
end
