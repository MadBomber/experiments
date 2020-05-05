#!/usr/bin/env ruby
#########################################
###
##  File:  class_tree_2.rb
##  Desc:  using ObjectSpace to print a class hierarchy
# See: http://blog.nicksieger.com/articles/2006/09/06/rubys-exception-hierarchy/
#      http://blog.nicksieger.com/articles/trackback/51
#

require 'awesome_print'


def class_hierarchy_for a_class

  class_array   = []
  tree          = {}

  ObjectSpace.each_object(Class) do |klass|
    next unless klass.ancestors.include? a_class
    next if class_array.include? klass

    if Exception == a_class
      next if klass.superclass == SystemCallError # ignore Errno
    end

    class_array << klass

    klass
      .ancestors
      .delete_if {|e| [Object, Kernel].include? e }
      .reverse
      .inject(tree) {|memo,klass| memo[klass] ||= {}}
  end # ObjectSpace.each_object(Class) do |klass|

  return tree
end

tree = class_hierarchy_for Exception # Numeric

puts "="*65
ap tree
puts "="*65


tab_size  = 2
indent    = 0

tree_printer = Proc.new do |t|
  t.keys.sort { |c1,c2| c1.name <=> c2.name }.each do |k|
    space   = (' ' * indent)
    space ||= ''

    puts space + k.to_s

    indent += tab_size
    tree_printer.call(t[k])
    indent -= tab_size
  end
end # tree_printer = Proc.new do |t|

tree_printer.call tree

