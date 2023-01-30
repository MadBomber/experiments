#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
# warn_indent: true
##########################################################
###
##  File: dagwood-graph.rb
##  Desc: Integrate Graph with Dagwood
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
##
#   dagwood is a simple library that uses the TSORT gem
#   to sort the elements of a Hash into an order based
#   upon dependencies.
#
#   graph is a gem wrapper of graphviz that produces
#   of graph structures.
#
#   brew install graphviz
#   gem install amazing_print dagwood graph
#

require 'amazing_print'
require 'dagwood'
require 'graph'

# Hash based upon the dagwood definitions were
# the key is dependent on the value.  Items within
# an array are not dependent upon each other.  They
# can be "worked" in parallel.
#
# Symbols are used because its more compact than strings
#
dinner = {
  # this task ..... depends on these tasks
  add_lettuce:      %i[get_the_bowl],
  add_tomatos:      %i[get_the_bowl],
  add_croutons:     %i[add_lettuce  add_tomatos],
  toss_salad:       %i[get_the_bowl add_lettuce add_tomatos],
  add_croutons:     %i[toss_salad],
  cook_roast:       %i[pre_heat_oven],
  set_the_table:    %i[],
  serve_salad:      %i[set_the_table  toss_salad],
  serve_roast:      %i[cook_roast     serve_salad],
  serve_the_dinner: %i[serve_salad    serve_roast]
}

# Adjust structure of the Array AND 
# change its entries to strings AND
# adds "Start" and "Done" as first and last entries
#
def normalize_array(thing_array)
  an_array = thing_array.dup

  an_array.map! do|e| 
    if e.is_a?(Array)
      if 1 == e.size
        e.first.to_s
      else
        e.flatten.map!{|r| r.to_s}
      end
    else
      e.to_s
    end
  end

  if  an_array.first.is_a?(Array) || 
      'start' != an_array.first.downcase
    an_array = an_array.prepend('Start')
  end

  if  an_array.last.is_a?(Array) ||
      'done' != an_array.last.downcase
    an_array << "Done"
  end

  ap an_array

  return an_array  
end


# global incremented with each new subgraph
$cluster_id = 0

# Adds a sub-graph (aka cluster) to the graphviz
# graph image.
#
# right is an Array of independent items
#
def build_subgraph(right)
  $cluster_id += 1

  cluster $cluster_id.to_s do
    attrs = "{rank=same"
    right.each do |r|
      attrs += ' "' + r + '"'
    end
    attrs += '}'
    graph_attribs << attrs

    # edge_attribs << "penwidth=0.0" << "arrowhead=none"

    (1..right.size-1).each do |x|
      edge(right[x-1], right[x])
        .attributes << "penwidth=0.0" << "arrowhead=none"
    end
  end # cluster $clunster_id.to_s do
end


# Simple graphviz with the "tasks" are have
# a specific order in which they must be worked.
# There are no parallel workers.
#
# name is a String, basename of output image
# type is a String, kind of image to produce
# an_array is a flatten Array
#
def simple_graph(name, type, thing_array)
  an_array = normalize_array(thing_array)  

  digraph do 
    boxes
    
    (1..an_array.size-1).each do |x|
      edge an_array[x-1], an_array[x]
    end
    
    circle << node("Start")
    circle << node("Done")  

    save name, type
  end
end


# Produces a complex graphviz image having one
# or more sub-graphs (aka clusters) indicating area
# where "tasks" can be worked in parallel.
#
# name is a String, basename of output image
# type is a String, kind of image to produce
# an_array is a flatten Array
#
def complex_graph(name, type, an_array_of_arrays)
  an_array = normalize_array(an_array_of_arrays)

  digraph do 
    graph_attribs << "compound=true" << "rankdir = TB"
    boxes

    (1..an_array.size-1).each do |x|
      left  = an_array[x-1]
      right = an_array[x]

      if left.is_a?(Array) 
        if right.is_a?(Array)
          # A->A        
          build_subgraph(right)

          edge(left.first, right.first)
            .attributes << "ltail=cluster_#{$cluster_id-1}" << "lhead=cluster_#{$cluster_id}"
        else
          # A -> N
          edge(left.first, right)
            .attributes << "ltail=cluster_#{$cluster_id}" 
        end
      else
        if right.is_a?(Array)
          # N->A
          build_subgraph(right)

          edge(left, right.first)
            .attributes << "lhead=cluster_#{$cluster_id}" 
        else
          # N->N
          edge(left, right)
        end
      end
    end
    
    circle << node("Start")
    circle << node("Done")

    save name, type
  end
end

##############################################

# Create the dagwood object (dw) from the
# Hash that defines how to server dinner
#
dw  = Dagwood::DependencyGraph.new(dinner)

# Create some image files

simple_graph("o",   "png", dw.order)
simple_graph("ro",  "png", dw.reverse_order)
complex_graph("po", "png", dw.parallel_order)

