#!/usr/bin/env ruby
#########################################
###
##  File:  class_tree.rb
##  Desc:  testing ways of finding sub-classes of a parent class
#

require 'rubygems'
require 'pp'


class MasterBaseClass

  @@sub_classes = []
  
  def self.inherited(sub)
    @@sub_classes << sub
  end
  
  def self.sub_classes
    return @@sub_classes
  end
end

class One < MasterBaseClass
end

class Two < MasterBaseClass
end

class Three < MasterBaseClass
end

class OneOne < One
end

class OneTwo < One
end

class OneOneOne < OneOne
end


puts "Subclasses of MasterBaseClass:"
MasterBaseClass.sub_classes.each do |sc|
  puts "  SubClass: #{sc}  Parent: #{sc.superclass}"
end

puts "Subclasses of One:"
One.sub_classes.each do |sc|
  puts "  #{sc}" if One == sc.superclass
end

puts "Subclasses of OneOne:"
OneOne.sub_classes.each do |sc|
  puts "  #{sc}" if OneOne == sc.superclass
end

puts "="*45

#########################################################
## Test IseMessages

puts "Testing with IseMessage"
puts

require 'StkLaunchMissile'; puts "StkLaunchMissile loaded."
require 'TruthTargetStates'; puts "TruthTargetStates loaded."
require 'EndRun'; puts "EndRun loaded."
require 'InitCase'; puts "InitCase loaded."
require 'InitCaseComplete'; puts "InitCaseComplete loaded."
require 'EndCase'; puts "EndCase loaded."
require 'EndCaseComplete'; puts "EndCaseComplete loaded."
require 'EndRun'; puts "EndRun loaded."
require 'EndRunComplete'; puts "EndRunComplete loaded."
require 'AdvanceTime'; puts "AdvanceTime loaded."
require 'TimeAdvanced'; puts "TimeAdvanced loaded."
require 'StartFrame'; puts "StartFrame loaded."
require 'SamsonHeader'; puts "SamsonHeader loaded."

puts

if defined? IseMessage
  
  puts "Sub-classes of IseMessage:"
  IseMessage.sub_classes.each do |sc|
    puts "  SubClass: #{sc}  Parent: #{sc.superclass}"
  end

else

  puts "IseMessage is not defined."

end

puts
outs "Done."


