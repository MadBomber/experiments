#!/usr/bin/env ruby

require 'dnssd'

DNSSD.register 'IseNetworkGateway', '_IsePrincess._tcp.', 'local', 50002

sleep 30

# the registration goes away when the program terminates

