#!/usr/bin/env ruby
# experiments/photography/eclipse_totality.rb
#
# See: https://yboulkaid.com/2024/04/10/eclipse.html

require 'gphoto2'

GPhoto2::Camera.first do |camera|
  speeds = %w[
    1/60
    1/4000
    1/2000
    1/500
    1/250
    1/15
    1/4
    1
    2
    4
  ]
  4.times do
    speeds.map do |speed|
      camera.update(iso: 400, shutterspeed: speed)
      4.times do
        puts "Taking exposure at #{speed}s"
        camera.capture
      rescue 
        nil # Cover for unexpected cases when e.g. the camera is busy
      end
    end
  end
end

