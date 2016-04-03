#!/usr/bin/env ruby
#############################################
###
##  File: ast_for_entity_relationship.rb
##  Desc: notional thought on object relationships
##
##  This is really an investigation into a manual way of
##  generating an AST for text in the process of entity
##  relationship extraction.
##
# TODO: aka needs to be linked to all information
#       still all the duples are not linked.  Need to
#       rethink everything.
#

usage = <<EOS

usage: pgm [options] data_file [search terms]

Options:

  --debug         Turn on debuging stuff

Where:

  data_file       Is a path to a text file
  [search terms]  Optional search terms

EOS

DEBUG = ARGV.include?('--debug')
def debug?; DEBUG; end

if ARGV.empty?              ||
   ARGV.include?('-h')      ||
   ARGV.include?('--help')
  puts usage
  exit -1
end

until ARGV.empty? || !ARGV.first.start_with?('-') do
  ARGV.shift
end

if ARGV.empty?
  puts usage
  exit -1
end

data_filename = ARGV.shift

require 'awesome_print'
require 'debug_me'
include DebugMe

require 'sycamore_helpers'

my_data_tree = Sycamore::Tree.new

spaces_per_tab = "  "

def extract_name_value(a_string)
  a_line  = a_string.strip
  parts   = a_line.split
  name    = parts.shift
  return name.to_sym, parts.join(' ')
end


def top_of_subtree(name, value, path)
  sub_tree_path = path.to_a.reverse
  until value == sub_tree_path[0] && name == sub_tree_path[1] do
    sub_tree_path.shift
  end
  sub_tree_path.reverse
end # def top_of_subtree(name, value, path)

prev_indent = 0

node_stack  = []

data_file = File.open(data_filename, 'r')

data_file.each_line do |a_line|
  a_line.chomp!
  next if a_line.strip.empty?
  next if a_line.lstrip.start_with?('#')
  break if a_line.lstrip.start_with?('__END__')

  # This input format has the same problem as Python
  # FIXME: replace indention level indicator (relationship) with '>'
  #        so that linear format can also be supported like:
  #        name value > name value > name value
  #        would be the same as:
  #        
  #        name value
  #          name value
  #            name value
  #        
  #    and
  #        
  #        name value
  #        > name value
  #        >> name value
  #        
  a_line.gsub!("\t", spaces_per_tab)

  name, value = extract_name_value(a_line)

  indent_level = a_line.length - a_line.lstrip.length

  if 0 == indent_level
    node_stack  = []
    my_data_tree.insert({name => value})
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

    my_data_tree.insert({name => value}, path_to_here)

    node_stack.push [indent_level, name, value]

  end # end of if 0 == indent_level

end # end of DATA.each_line do |a_line|


##########################################
## simplify and combine nodes
## The first node defined is a top-level node of interest
## All other top-level nodes are pending data items not
## yet associated with the defined top-level node

total_top_level_nodes = my_data_tree.size

root_tree_name    = my_data_tree.nodes.first
root_tree_values  = my_data_tree[root_tree_name].nodes

if total_top_level_nodes >= 2
  nodes       = my_data_tree.nodes
  (1..total_top_level_nodes).each do |x|
    next_name   = nodes[x]
    next_values = my_data_tree[next_name].nodes
    next_values.each do |next_value|
      delete_the_sub_tree = false
      sub_tree    = my_data_tree[next_name, next_value]
      root_tree_values.each do |root_tree_value|
        root_tree   = my_data_tree[root_tree_name, root_tree_value]
        paths       = root_tree.search({next_name => next_value})
        unless paths.empty?
          paths.each do |path|
            root_tree.insert(sub_tree, [next_name, next_value])
            delete_the_sub_tree = true
          end
        end # unless paths.empty?
      end # root_tree_values.each do |root_tree_value|
      my_data_tree.delete({next_name => next_value}) if delete_the_sub_tree
    end # next_values.each do |next_value|
  end # (1..total_top_level_nodes).each do |x|
end # if total_top_level_nodes >= 2




unless ARGV.empty?
  ARGV.each do |search_term|
    next if search_term.start_with?('-')
    puts "\n\n"
    puts "#"*45
    puts "## Search term: #{search_term}"
    ap my_data_tree.string_search(search_term)
  end
else
  puts "\n\nAdd some search terms to the command line.  See what pops out.\n\n"
end

__END__
