require 'rubygems'
require 'eventmachine'
require 'pp'

udp_ip   = '127.0.0.1'
udp_port = 1234

module CustomServer
    def receive_data d
        pp get_peername[2,6].unpack 'nC4'
    end
end


EventMachine::run {
    EventMachine::open_datagram_socket udp_ip,
        udp_port,
        CustomServer
}
