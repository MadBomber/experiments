#!/usr/bin/env ruby
#############################################
###
## 	File: threat_analysis.rb
##  Desc: notional thought on object relationships
#
=begin
  
What I seem to be moving toward is a graph in which the
indention represents inclusion and the first word
represents an edge 'name'

For example

node name
  is_a top_level_node

would generate a graph component like:

  "node name"  --- "is_a" --=> "top_level_node"

I should be able to represent this in dot notation for graphvis

This almost sounds like a mindmap.

=end

class Node
  def initialize(name, &block)
    @name = name
    @children = []

    instance_eval(&block) if block
  end

  attr_reader :children, :name

  def node(name, &block)
    children << Node.new(name, &block)
  end
end


Node.new('root') do
  node('branch') do
    node('leaf')
    node('leaf2')
    node('leaf3')
  end
end


require 'hashie'
require 'awesome_print'

db = Array.new

class DbEntry < Hashie::Mash
end

dsl_commands = Array.new

DATA.each_line do |a_line|
  puts a_line
  left_shifted = a_line.strip
  next if left_shifted.empty?
  next if left_shifted.start_with? '#'
  left_shifted_parts = left_shifted.split
  command = left_shifted_parts.shift.downcase
  rest = left_shifted_parts
  dsl_commands << command unless  dsl_commands.include? command
end

ap dsl_commands


__END__

area Khorasan
  area Afghanistan
  area Pakistan

prophecy foretold the coming of an unstoppable army bearing black flags that would emerge from Khorasan
  attributed_to Mohammed

area America
  aka US
  aka USA
  aka United States
  aka United States of America
  aka far enemy

person Ibrahim al Asiri
  is_a bomb_maker

explosive PETN
  is_a white
  is_a powdery
  is_a difficult-to-detect explosive

threat Tehreek-e-Taliban Pakistan
  aka TTP
  person Hafez Saeed Khan
    is_a commander


person Abu Muhammad al-Adnani
  aka al-Adnani
  is_a spokesperson for the Islamic State

threat AQAP
  aka al Qaeda in the Arabian Peninsula

threat Khorasan
  aka Khorasan group
  aka Khurasan
  is_a group of senior al-Qaeda members
  ideology Salafi jihadism
    defined_as a transnational religious-political ideology based on a belief in violent jihad and the Salafist religious movement of returning to (what adherents believe is) "true" Sunni Islam
  plans_to strik targets in the United States and Europe
  composed_of former Al-Qaeda operatives
    from Middle East
    from North Africa
    from South Asia
  terror_method concealed explosives
  person Abdelrahman al Johani
    aka Al Johani
    is_a bomb_maker
    is_a counterintelligence chief
    born 1970
      in Saudi Arabia
    trained explosives
    trained toxins
  person Mohammed Islambouli
  person Abdul al Charekh
    is_a internet propagandist
    is_a money_man
    born 1985
  person Adel Radi Saqr al-Wahabi al-Harbi
    is_a leader
    died march 2015
      in Idlib, Syria
  person David Drugeon
    nationality french
    is_a bomber_maker
    died march 2015
      in Idlib, Syria
  person Muhsin al-Fadhli
    aka Abu Majid Samiyah
    aka Abu Samia
    aka Dawud al-Asadi
    aka Muhsin Fadhil Ayyid al-Fadhli
    aka Muhsin Fadil Ayid Ashur al-Fadhli
    is_a senior_leader
    close_to Osama bin Laden
    born 24 April 1981
      in  Kuwait
    died 8 July 2015
      in Sarmada, Syria
    credited_by US State Department
      in 2012
      as leader of the Iranian branch of Al-Qaeda
    works_with wealthy “jihadist donors”
      in Kuwait
	credited_by Former President George W. Bush
	  in 2005
	  as leader
	  event French oil tanker bombing
	    in 2002
  person al-Zawahiri
    is_a senior_leader
    influence weak
  person Ibrahim al-Asiri 
    is_a bomb_maker
    linked_to  Al-Qaeda
    is_a true pioneer of hard-to-detect bombs
  intends_to recruit European and American Muslim militants
  intends_to train and deploy these recruits, who hold American and European passports, for attacks against Western targets
  linked_to Al-Qaeda
    as new arm in attacking America
  linked_to Al Nusra
    as allies
    in Syria
  scope global

############################################
threat isis
  aka is
  aka isil
  aka islamic state
  scope regional

#############################################
threat Al Nusra
  aka Nusra Front
  aka Al Nusra Front
  aka Jabhat al Nusra
  linked_to Al-Qaeda
    as official branch
    in Syria

############################################
threat Ahrar al Sham
  aka Harakat Ahrar ash-Sham al-Islamiyya
  aka Islamic Movement of the Free Men of the Levant
  ideology Sunni Islamism
  ideology Salafism
  person Hassan Aboud
    is_a leader
  person Abu Jaber
    is_a leader
  influnces Syrian Sunnis

#############################################
threat Al-Qaeda
  person Ayman al-Zawahiri
    is_a leader
    is_a emir


