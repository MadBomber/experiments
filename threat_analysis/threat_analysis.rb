#!/usr/bin/env ruby
#############################################
###
##  File: threat_analysis.rb
##  Desc: notional thought on object relationships
##
# TODO: given a new top-level node, find all existing sub-nodes
#       that match given name, value and attach new information to
#       those sub-nodes.  In other words, don't create a top-level
#       node if the information is already in the tree at a lower
#       level.  Does this mean that there might be duplicate sub-nodes? yes.
#       Is that bad? yea, but will deal with that later.

DEBUG = ARGV.include?('--debug')
def debug?; DEBUG; end

require 'awesome_print'
require 'debug_me'
include DebugMe

require 'sycamore'

module Sycamore
  class Tree
    def search(a_string)
      self.each_path.select{|a_path| a_path.join('/').downcase.include?(a_string.downcase)}
    end
  end
end

notes = Sycamore::Tree.new

spaces_per_tab = "  "

def extract_name_value(a_string)
  a_line  = a_string.strip
  parts   = a_line.split
  name    = parts.shift
  return name.to_sym, parts.join(' ')
end

prev_indent = 0

node_stack  = []

DATA.each_line do |a_line|
  a_line.chomp!
  next if a_line.strip.empty?
  next if a_line.lstrip.start_with?('#')

  a_line.gsub!("\t", spaces_per_tab)

  name, value = extract_name_value(a_line)

  indent_level = a_line.length - a_line.lstrip.length

  if 0 == indent_level
    node_stack  = []
    notes[name] << value
    node_stack.push [indent_level, name, value]
  else
    last_node = node_stack.last

    if indent_level == last_node[0]
      node_stack.pop 
    elsif indent_level < last_node[0]
      until (last_node[0] < indent_level) do        
        node_stack.pop
        last_node = node_stack.last
      end
    end
    
    path_to_here = []

    node_stack.each do |node|
      path_to_here << node[1].to_sym
      path_to_here << node[2]
    end

    path_to_here << name

    node_stack.push [indent_level, name, value]

    notes[ path_to_here ] << value

  end

 puts node_stack.inspect if debug?

end

if debug?
  ap notes.to_h

  notes.each_path do |a_path|
    puts a_path.join('/')
  end

  ap notes.search('leader')
end # if testing?

unless ARGV.empty?
  ARGV.each do |search_term|
    next if search_term.start_with?('-')
    puts "\n\n"
    puts "#"*45
    puts "## Search term: #{search_term}"
    ap notes.search(search_term)
  end
else
  puts "\n\nAdd some search terms to the command line.  See what pops out.\n\n"
end

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

explosive TAPT 

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
  plans_to strike targets in the United States and Europe
  composed_of former Al-Qaeda operatives
    area Middle East
    area North Africa
    area South Asia
  terror_method concealed explosives
  person Abdelrahman al Johani
    aka Al Johani
    is_a bomb_maker
    is_a counterintelligence chief
    date_born 1970
      area Saudi Arabia
    trained_in explosives
    trained_in toxins
  person Mohammed Islambouli
  person Abdul al Charekh
    is_a internet propagandist
    is_a money_man
    date_born 1985
  person Adel Radi Saqr al-Wahabi al-Harbi
    is_a leader
    date_died march 2015
      area Idlib, Syria
  person David Drugeon
    nationality french
    is_a bomber_maker
    date_died march 2015
      area Idlib, Syria
  person Muhsin al-Fadhli
    aka Abu Majid Samiyah
    aka Abu Samia
    aka Dawud al-Asadi
    aka Muhsin Fadhil Ayyid al-Fadhli
    aka Muhsin Fadil Ayid Ashur al-Fadhli
    is_a senior_leader
    close_to Osama bin Laden
    date_born 24 April 1981
      area  Kuwait
    date_died 8 July 2015
      area Sarmada, Syria
    credited_by US State Department
      date 2012
      as leader of the Iranian branch of Al-Qaeda
    works_with wealthy “jihadist donors”
      area Kuwait
  credited_by Former President George W. Bush
    date 2005
    as leader
    event French oil tanker bombing
      date 2002
  person al-Zawahiri
    is_a senior_leader
    influence_is weak
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
    area Syria
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
    area Syria

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


