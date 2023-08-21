#!/usr/bin/env ruby

require 'tty-option'

class One
  include TTY::Option

  usage   { desc 'command_option [options]' }
  header  'Application options:'

  option :name do
    short '-n'
    long '--name NAME'
    desc 'Set the name'
    required
  end

  option :age do
    short '-a'
    long '--age AGE'
    desc 'Set the age'
    convert :int
  end
end

class Two
  include TTY::Option

  usage   { desc 'another_command_option [options]' }
  header  'Another application options:'

  option :username do
    short '-u'
    long '--username USERNAME'
    desc 'Set the username'
  end

  option :password do
    short '-p'
    long  '--password PASSWORD'
    desc  'Set the password'
  end
end

if ARGV[0] == 'one'
  one = One.new
  one.parse

  if one.params[:help]
    puts one.help
  else
    puts "Name: #{one.params[:name]}"
    puts "Age: #{one.params[:age]}"
  end

elsif ARGV[0] == 'two'
  two = Two.new
  two.parse

  if two.params[:help]
    puts two.help
  else
    puts "Username: #{two.params[:username]}"
    puts "Password: #{two.params[:password]}"
  end
else
  puts "Command not supported!"
end
