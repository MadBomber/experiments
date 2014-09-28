#!/bin/env ruby
require 'socket'

#abort "Usage: server_addr, server_port, cmd_str" unless ARGV.length == 3

UDP_RECV_TIMEOUT = 3  # seconds

def q2cmd(server_addr, server_port, cmd_str)
  resp, sock = nil, nil
  begin
   cmd = "\377\377\377\377#{cmd_str}\0"
    sock = UDPSocket.open
    sock.send(cmd, 0, server_addr, server_port)
    resp = if select([sock], nil, nil, UDP_RECV_TIMEOUT)
      sock.recvfrom(65536)
    end
    if resp
      resp[0] = resp[0][4..-1]  # trim leading 0xffffffff
    end
  rescue IOError, SystemCallError
  ensure
    sock.close if sock
  end
  resp ? resp[0] : nil
end

# your firewall has to allow communication with IP address 67.19.248.74 (port 27912)
#server, port, cmd = *ARGV
server = "tastyspleen.net"
port = 27912
cmd = "status"

result = q2cmd(server, port, cmd)
puts result



