#!/bin/env ruby
#################################################################
###
##  File: clone_vm.rb
##  Desc: Makes linked clones of a given VM/snapshot
#

require 'virtualbox'
require 'systemu'
require 'pp'

base_vm_name      = "ise"
base_vm_snapshot  = "login"

clone_vm_basename = "#{base_vm_name}-"

def start_all_vm
  VirtualBox::VM.all.each {|v| v.start unless v.running?}
end

def stop_all_vm
  VirtualBox::VM.all.each {|v| v.stop if v.running?}
end

def save_all_vm
  VirtualBox::VM.all.each {|v| v.save_state if v.running?}
end

#######################
def start_ise_vm
  VirtualBox::VM.all.each {|v| v.start if !v.running? and v.name.start_with? 'ise'}
end

def stop_ise_vm
  VirtualBox::VM.all.each {|v| v.stop if v.running? and v.name.start_with? 'ise'}
end

def save_ise_vm
  VirtualBox::VM.all.each {|v| v.save_state if v.running? and v.name.start_with? 'ise'}
end



#######################
def start_clones_of(source_vm_name)
  VirtualBox::VM.all.each do |v|
    if !v.running? and v.name.start_with? "#{source_vm_name}-"
      v.start
      sleep 2
      set_hostname_of_clone(v.name)
    end
  end
end

def stop_clones_of(source_vm_name)
  VirtualBox::VM.all.each do |v|
    if v.running? and v.name.start_with? "#{source_vm_name}-"
      v.stop
      sleep 2
    end
  end
end

def save_clones_of(source_vm_name)
  VirtualBox::VM.all.each do |v|
    if v.running? and v.name.start_with? "#{source_vm_name}-"
      v.save_state
      sleep 2
    end
  end
end



###################################################
## Functions not supported by the virtualbox gem ##
###################################################

def vbm (a_command_string)
  a_command = "VBoxManage #{a_command_string}"
  puts "Command: " + a_command
  a,results,c = systemu a_command
#  puts a
#  puts "--"
#  puts results
#  puts "--"
#  puts c
  return results
end


def clone_vm(source_vm_name, source_vm_snapshot, how_many=1)
  how_many.times do |x|
    v = x+1
    new_name = "#{source_vm_name}-#{v}"
    vm = VirtualBox::VM.find(new_name)
    unless vm
      vbm("clonevm #{source_vm_name} --snapshot #{source_vm_snapshot} --name #{new_name} --options link --register")
      sleep 2
    end
  end
end


def delete_clones_of(source_vm_name)
  clone_vm_basename = "#{source_vm_name}-"
  stop_clones_of(source_vm_name)
  
#  puts "sleeping 15 to ensure that all are stopped"
#  sleep 15
  
  VirtualBox::VM.all.each do |v|
    if !v.running? and v.name.start_with? "#{source_vm_name}-"
      puts vbm("unregistervm #{v.name} --delete")
      sleep 2
    end
  end
end


def set_hostname_of_clone(source_vm_name, account='root', password='iseisnice')
  vm = VirtualBox::VM.find(source_vm_name)
  if vm and vm.running?
    # This only works after the VM has been booted AND
    # if the VirtualBoxGuessAdditions has been installed
    # This only changes the hostname during this invocation.  The
    # next time the VM is launched it will have its original hostname.
    results = vbm("guestcontrol #{source_vm_name} exec /bin/hostname --username #{account} --password #{password} -- #{source_vm_name}")
    puts "Results: " + results
    # On RedHat/Fedora a modification must be made to the file
    # /etc/sysconfig/network
    # The line that looks like
    # HOSTNAME=xxxxxx
    # needs to changed such that the xxxxxx (representing the base_hostname from which
    # the clone was made) such be replaced with the new desired hostname of the clone.
    # TODO: how will that work with a cloned that is linked to the base VM disk?
    # Also need to change the entries for DHCP_HOSTNAME and DHCP_CLIENT_ID in the
    # /etc/sysconfig/network-scripts/ifcfg-* files usually just eth0
    # TODO: may have to killall dhclient; sleep 2; service network restart
    # Lots of places in /etc to change the hostname; consider something like
    # find /etc -type f -exec sed 's/base-name/clone-name/g' {} \;
    # WARNING: "ise" is too generic for the base-name think about something else
    #          like maybe ise-master and the clones as ise-clone-1 etc.
  end
end



clone_vm(base_vm_name, base_vm_snapshot, 3)

puts vbm("list vms")

start_clones_of base_vm_name

puts "Counting down ..."
45.times do |x|
  printf "%d \r", 45-x
  sleep 1
end
puts

#puts "Now deleting ..."
#delete_clones_of base_vm_name



puts "Done."

