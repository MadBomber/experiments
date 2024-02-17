#!/usr/bin/env ruby
# experiments/prolog/test.rb

require 'amazing_print'
require 'debug_me'
include DebugMe

require_relative 'knowledge_base'
require_relative 'person'


def bar(char: '=', width: 60)
  puts "#{char}"*width
end


def section(title:, char: '=', width: 60)
  print "\n\n"
  bar(char: char, width: width)
  puts ("#{char}"*2) + " #{title}"
  puts
end

section title: "Setup"

# Creating instances of the Person class
dewayne = Person.new(1, "Dewayne",  :male,    70)
ella    = Person.new(2, "Ella",     :female,  64)
diane   = Person.new(3, "Diane",    :female,  24)
janet   = Person.new(4, "Janet",    :female,  22)

people    = [dewayne, ella, diane, janet]
parents   = people.slice(0..1)
children  = people.slice(2..3)

# Creating instances of Fact
kb = KnowledgeBase.new

# Initializing a married fact
kb << Fact.new(dewayne, :married_to, ella).inverse

# Initializing parent facts
parents.each do |parent|
  predicate = parent.sex == :male ? :father_of : :mother_of
  children.each do |child|
    kb.add Fact.new(parent, predicate, child)
  end
end


kb.flatten!



# Demonstrating the use of these facts
puts "Facts about the People:"
puts

kb.each do |fact|
  puts fact
end


###########################################
section title: "Testing Object Equivalence"

# First, find Diane object using the name attribute to ensure the object passed matches the one used in the knowledge base
diane_object = people.find { |person| person.name == 'Diane' }

if diane == diane_object
  title = "== same =="
else
  title = "== different =="
end

debug_me(title){[
  "diane.object_id",
  "diane_object.object_id"
]}


###############################
section title: "Query Test One"

# Now form a query to find Diane's father using the KnowledgeBase#query method.
# We represent unknowns with :unk, so we're looking for a fact pattern where
# The head is ?: (unknown), the predicate is :father_of, and the objects include Diane.
query_fact = Fact.new(nil, :father_of, diane_object)

# Execute the query against the knowledge base
dianes_fathers = kb.query(query_fact)

# Assuming there's only one father in this context, or we're only interested in the first result
if dianes_fathers.any?
  # Extracting the father's name from the first result
  dianes_father = dianes_fathers.first.head.name
  puts "Diane's father is: #{dianes_father}"
else
  puts "Diane's father couldn't be found in the knowledge base."
end


###############################
section title: "Query Test Two"


q_fact  = Fact.new(dewayne, :father_of, nil)
kids    = kb.query(q_fact, false)

puts kids.map{|k| k.to_s}


#################################
section title: "Query Test Three"

q_fact        = Fact.new(dewayne, nil, ella)
relationships = kb.query(q_fact)

puts relationships.map{|r| r.to_s}

