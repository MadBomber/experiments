#!/usr/bin/env ruby
##########################################################
###
##  File: ballistics_test.rb
##  Desc: Just playing with the gem
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'pp'

# Ballistics for small-arms

require 'ballistics'
require "ballistics/utils"

environment = Ballistics.build_environment(
                              altitude:             5430,   # Feet
                              barometric_pressure:  29.93,  # mm of Hq
                              temperature:          40,     # degrees F
                              relative_humidity:    0.48
                            )

pp environment

atmosphere = Ballistics::Atmosphere.new(
                            altitude:             5430,
                            barometric_pressure:  29.93,
                            temperature:          40,
                            relative_humidity:    0.48
                          )

pp atmosphere

trajectory = Ballistics.map_trajectory(
                            drag_function:    'G1',
                            drag_coefficient: 0.5,
                            velocity:         2850,         # feet per second
                            sight_height:     1.6,          # inches
                            wind_speed:       10,           # miles per hour
                            wind_angle:       90,           # degrees relative to barrel
                            zero_range:       200,          # feet
                            max_range:        1000,         # feet
                            environment:      environment,
                            interval:         25            # distance in feet
                          )

puts "trajectory.size #{trajectory.size}"

pp trajectory.first

pp trajectory.last

keys = trajectory.first.keys

puts keys.join("\t")

trajectory.each do |a_hash|
  keys.each do |k|
    print "#{a_hash[k].round(7)}\t"
  end
  puts
end



options =
    {
      drag_function:    'G1',
      drag_coefficient: 0.5,
      velocity:         1200,   # feet per second
      sight_height:     1.6,    # inchs
      zero_range:       100     # feet
    }

pp options

zero_angle = Ballistics::Zero.calculate_zero_angle(options)
puts "zero_angle               #{zero_angle}"

bullet_sectional_density = Ballistics::Utils.sectional_density(230, 0.451)
puts "bullet_sectional_density #{bullet_sectional_density}"

kinetic_energy  = Ballistics::Utils.kinetic_energy(800.0, 230)
puts "kinetic_energy           #{kinetic_energy}"

taylor_knockout = Ballistics::Utils.taylorko(800.0, 230, 0.452)
puts "taylor_knockout          #{taylor_knockout}"

recoil_impulse  = Ballistics::Utils.recoil_impulse(150, 46, 2800)
puts "recoil_impulse           #{recoil_impulse}"

free_recoil     = Ballistics::Utils.free_recoil(150, 46, 2800, 8)
puts "free_recoil              #{free_recoil}"




