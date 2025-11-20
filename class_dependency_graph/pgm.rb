#!/usr/bin/env ruby

require 'amazing_print'

require 'debug_me'
include DebugMe

require 'set'

# Define a simple node to represent each class
class Node
  attr_reader :name
  attr_accessor :children

  def initialize(name)
    @name     = name
    @children = []
  end
end


# Parse the tags file to build a dependency graph
def parse_tags_file(filepath)
  # Hash to store class Nodes, keyed by class name
  nodes = Hash.new { |h, k| h[k] = Node.new(k) }
  
  # Set to keep track of base classes that might not have a explicit definition in the tags file
  base_classes = Set.new

  File.foreach(filepath) do |line|
    data = line.split
    next unless data.last.include?('class') # Focus only on class definitions

    class_name, parent_class = parse_class_definition(data[0], line)
    unless parent_class.nil?
      nodes[parent_class].children << nodes[class_name] unless nodes[parent_class].children.include?(nodes[class_name])
      base_classes.delete(parent_class) # If a parent class is also a child, remove from base_classes
    else
      base_classes.add(class_name) # Add as a potential base class
    end
  end

  [nodes, base_classes]
end


# Extracts the class name and its parent (if any) from a line
def parse_class_definition(tag, line)
  class_name = tag
  parent_class = line.match(/<\s*(\S+)/)&.captures&.first
  [class_name, parent_class]
end


# Method to print the class dependency graph recursively
def print_dependencies(node, level = 0)
  puts "#{'  ' * level}#{node.name}"
  node.children.each do |child|
    print_dependencies(child, level + 1)
  end
end


# Main method to execute the script
def main(tags_file)
  nodes, base_classes = parse_tags_file(tags_file)

  base_classes.each do |base_class_name|
    print_dependencies(nodes[base_class_name])
  end
end


# Replace 'path/to/tags_file' with the path to your actual tags file
tags_file = 'tags'
main(tags_file)
