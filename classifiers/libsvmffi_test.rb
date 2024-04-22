#!/usr/bin/env ruby
###################################################
###
##  File: libsvmffi_test.rb
##  Desc: simple classifier
#

require 'amazing_print'

begin
  require 'libsvmffi'
rescue Exception => e
  if e.to_s.start_with?("Could not open library")
    puts "ERROR: Could not find the svm library."
    puts "       Check $LD_LIBRARY_PATH"
  else
    puts "ERROR: #{e}"
  end
  exit(-1)
end

m = Libsvmffi::Model.new
m.add :good, {:height => 1, :width => 1, :length => 1}
m.add :bad, {:height => 10, :width => 3, :length => 6}
m.train

puts m.classify({:height => 1, :width => 1.1, :length => 1})    #=> :good

