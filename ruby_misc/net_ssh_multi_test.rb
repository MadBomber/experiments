##############################################
###
##  File:   net_ssh_multi_test.rb
##  Desc:   Just testing
#

require 'net/ssh'

Net::SSH.start('10.0.52.139', 'dvanhoozer', :password => ENV["xyzzy"]) do |ssh|
    # capture all stderr and stdout output from a remote process
    output = ssh.exec!("hostname")

    # capture only stdout matching a particular pattern
    stdout = ""
    ssh.exec!("ls -l /home/dvanhoozer") do |channel, stream, data|
      stdout << data if stream == :stdout
    end
    puts stdout

    # run multiple processes in parallel to completion
    ssh.exec "echo 'one'"
    ssh.exec "echo 'two'"
    ssh.exec "echo 'three'"
    ssh.loop

=begin
    # open a new channel and configure a minimal set of callbacks, then run
    # the event loop until the channel finishes (closes)
    channel = ssh.open_channel do |ch|
      ch.exec "/usr/local/bin/ruby /path/to/file.rb" do |ch, success|
        raise "could not execute command" unless success

        # "on_data" is called when the process writes something to stdout
        ch.on_data do |c, data|
          $STDOUT.print data
        end

        # "on_extended_data" is called when the process writes something to stderr
        ch.on_extended_data do |c, type, data|
          $STDERR.print data
        end

        ch.on_close { puts "done!" }
      end
    end

    # channel.wait

    # forward connections on local port 1234 to port 80 of www.capify.org
    # ssh.forward.local(1234, "www.capify.org", 80)
    # ssh.loop { true }

=end


end


###################################################################
=begin
require 'net/ssh/multi'

Net::SSH::Multi.start do |session|
    # access servers via a gateway
    # session.via 'gateway', 'gateway-user'

    # define the servers we want to use
    # session.use "dvanhoozer@10.0.52.103/#{ENV['xyzzy']}"
    # session.use "dvanhoozer@10.0.52.139/#{ENV['xyzzy']}"

    # define servers in groups for more granular access
    session.group :ise do
        session.use "dvanhoozer@10.0.52.103/#{ENV['xyzzy']}"
        session.use "dvanhoozer@10.0.52.139/#{ENV['xyzzy']}"
    end

    # execute commands on all servers
    session.exec "uptime"

    # execute commands on a subset of servers
    session.with(:ise).exec "hostname"

    # run the aggregated event loop
    session.loop
end
=end
