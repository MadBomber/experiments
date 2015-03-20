#!/usr/bin/env ruby

require 'state_machine'
require 'awesome_print'

# TODO: convert to a minitest

class Vehicle
  attr_accessor :seatbelt_on

  state_machine :state, :initial => :parked do
    before_transition :parked => any - :parked, :do => :put_on_seatbelt

    after_transition :on => :crash, :do => :tow
    after_transition :on => :repair, :do => :fix


    after_transition any => :parked do |vehicle, transition|
      puts "after_transition any => :parked"
      vehicle.seatbelt_on = false
    end # after_transition any => :parked do |vehicle, transition|

    event :park do
      puts "park"
      transition [:idling, :first_gear] => :parked
    end # event :park do

    event :ignite do
      puts "ignite"
      transition :stalled => same, :parked => :idling
      transition any => :on
    end # event :ignite do

    event :idle do
      puts "idle"
      transition :first_gear => :idling
    end # event :idle do

    event :shift_up do
      puts "shift_up"
      transition :idling => :first_gear, :first_gear => :second_gear, :second_gear => :third_gear
    end # event :shift_up do

    event :shift_down do
      puts "shift_down"
      transition :third_gear => :second_gear, :second_gear => :first_gear
    end # event :shift_down do

    event :crash do
      puts "crash"
      transition all - [:parked, :stalled] => :stalled, :unless => :auto_shop_busy?
      transition any => :off
    end # event :crash do

    event :repair do
      puts "repair"
      transition :stalled => :parked, :if => :auto_shop_busy?
    end # event :repair do

    state :parked do
      puts "parked"
      def speed
        puts "speed 0"
        return 0
      end # def speed
    end # state :parked do

    state :idling do
      puts "idling"
      def speed
        puts "speed 5"
        return 5
      end # def speed
    end # state :idling do

    state :idling, :first_gear do
      puts "idling or first_gear"
      def speed
        puts "speed 10"
        return 10
      end # def speed
    end # state :idling, :first_gear do

    state :first_gear do
      puts "first_gear"
      def speed
        puts "speed 15"
        return 15
      end # def speed
    end # state :first_gear do

    state :second_gear do
      puts "second_gear"
      def speed
        puts "speed 20"
        return 20
      end # def speed
    end # state :second_gear do

    state :third_gear do
      puts "third_gear"
      def speed
        puts "speed 65"
        return 65
      end # def speed
    end # state :third_gear do

    state :stalled do
      puts "stalled"
      def speed
        puts "speed 0"
        return 0
      end # def speed
    end # state :stalled do

  end # state_machine :state, :initial => :parked do

  state_machine :alarm_state, :initial => :active, :namespace => 'alarm' do

    event :enable do
      puts "enable"
      transition all => :active
    end # event :enable do

    event :disable do
      puts "disable"
      transition all => :off
    end # event :disable do

    state :active, :value => 1
    state :off, :value => 0

  end # state_machine :alarm_state, :initial => :active, :namespace => 'alarm' do

  def initialize
    @seatbelt_on = false
    puts "initialize"
    super() # NOTE: This *must* be called, otherwise states won't get initialized
  end

  def put_on_seatbelt
    @seatbelt_on = true
    puts "put_on_seatbelt"
  end

  def auto_shop_busy?
    outs "auto_shop_busy?"
    false
  end

  def tow
    puts "tow the vehicle"
  end

  def fix
    puts "get the vehicle fixed by a mechanic"
  end

end # class Vehicle

vehicle = Vehicle.new           # => #<Vehicle:0xb7cf4eac @state="parked", @seatbelt_on=false>

puts vehicle.inspect

puts vehicle.state                   ; puts "Line: #{__LINE__}" # => "parked"
puts vehicle.state_name              ; puts "Line: #{__LINE__}" # => :parked
puts vehicle.parked?                 ; puts "Line: #{__LINE__}" # => true
puts vehicle.can_ignite?             ; puts "Line: #{__LINE__}" # => true
puts vehicle.ignite_transition       ; puts "Line: #{__LINE__}" # => #<StateMachine::Transition attribute=:state event=:ignite from="parked" from_name=:parked to="idling" to_name=:idling>
puts vehicle.state_events            ; puts "Line: #{__LINE__}" # => [:ignite]
puts vehicle.state_transitions.inspect       ; puts "Line: #{__LINE__}" # => [#<StateMachine::Transition attribute=:state event=:ignite from="parked" from_name=:parked to="idling" to_name=:idling>]
puts vehicle.speed                   ; puts "Line: #{__LINE__}" # => 0

puts vehicle.ignite                  ; puts "Line: #{__LINE__}" # => true
puts vehicle.parked?                 ; puts "Line: #{__LINE__}" # => false
puts vehicle.idling?                 ; puts "Line: #{__LINE__}" # => true
puts vehicle.speed                   ; puts "Line: #{__LINE__}" # => 10
puts vehicle                         ; puts "Line: #{__LINE__}" # => #<Vehicle:0xb7cf4eac @state="idling", @seatbelt_on=true>

puts vehicle.shift_up                ; puts "Line: #{__LINE__}" # => true
puts vehicle.speed                   ; puts "Line: #{__LINE__}" # => 10
puts vehicle                         ; puts "Line: #{__LINE__}" # => #<Vehicle:0xb7cf4eac @state="first_gear", @seatbelt_on=true>

puts vehicle.shift_up                ; puts "Line: #{__LINE__}" # => true
puts vehicle.speed                   ; puts "Line: #{__LINE__}" # => 20
puts vehicle                         ; puts "Line: #{__LINE__}" # => #<Vehicle:0xb7cf4eac @state="second_gear", @seatbelt_on=true>

begin
  # The bang (!) operator can raise exceptions if the event fails
  puts vehicle.park!                   ; puts "Line: #{__LINE__}" # => StateMachine::InvalidTransition: Cannot transition state via :park from :second_gear
rescue
  puts "rescued from a bad transition"
end

begin
  # Generic state predicates can raise exceptions if the value does not exist
  puts vehicle.state?(:parked)         ; puts "Line: #{__LINE__}" # => false
  puts vehicle.state?(:invalid)        ; puts "Line: #{__LINE__}" # => IndexError: :invalid is an invalid name
rescue
  puts "rescued from an invalid state"
end

# Namespaced machines have uniquely-generated methods
puts vehicle.alarm_state             ; puts "Line: #{__LINE__}" # => 1
puts vehicle.alarm_state_name        ; puts "Line: #{__LINE__}" # => :active

puts vehicle.can_disable_alarm?      ; puts "Line: #{__LINE__}" # => true
puts vehicle.disable_alarm           ; puts "Line: #{__LINE__}" # => true
puts vehicle.alarm_state             ; puts "Line: #{__LINE__}" # => 0
puts vehicle.alarm_state_name        ; puts "Line: #{__LINE__}" # => :off
puts vehicle.can_enable_alarm?       ; puts "Line: #{__LINE__}" # => true

puts vehicle.alarm_off?              ; puts "Line: #{__LINE__}" # => true
puts vehicle.alarm_active?           ; puts "Line: #{__LINE__}" # => false

# Events can be fired in parallel
puts vehicle.fire_events(:shift_down, :enable_alarm) ; puts "Line: #{__LINE__}" # => true
puts vehicle.state_name                              ; puts "Line: #{__LINE__}" # => :first_gear
puts vehicle.alarm_state_name                        ; puts "Line: #{__LINE__}" # => :active

begin
  puts vehicle.fire_events!(:ignite, :enable_alarm)    ; puts "Line: #{__LINE__}" # => StateMachine::InvalidTransition: Cannot run events in parallel: ignite, enable_alarm
rescue
  puts "rescued from invalid parallel events"
end

puts vehicle.inspect

# ap vehicle.methods.sort

puts "Done."
