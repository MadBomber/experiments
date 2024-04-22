#!/usr/bin/env ruby
# get_optional_defaults.rb

require 'method_source'

require 'debug_me'
include DebugMe

require_relative 'rules.rb'

module MethodAstIntrospector
  def self.extract_method_ast_and_defaults(module_name, method_name)
    method = module_name.method(method_name)
    source = method.source
    line_no = method.source_location.last

    # Parse the source code into AST
    ast = RubyVM::AbstractSyntaxTree.parse(source)

    # Initialize storage for default values
    defaults = {}

    traverse_ast(ast, defaults, line_no)

    defaults
  end

  def self.traverse_ast(node, defaults, target_line_no, inside_target_method: false)
    # Ensure node is indeed a node
    return unless node.is_a?(RubyVM::AbstractSyntaxTree::Node)

    # When the target method definition line has been reached or we're already inside the method
    if node.first_lineno == target_line_no || inside_target_method
      # Handle node types possibly containing method arguments with default values
      case node.type
      when :DEFN, :DEFS
        inside_target_method = true
      when :OPT_ARG
        param_name = node.children[0].children[0] # Extract parameter name
        default_value_node = node.children[1] # Node that represents default value
        defaults[param_name] = evaluate_default_value_node(default_value_node)
      end
    end

    # Traverse children
    node.children.each do |child|
      traverse_ast(child, defaults, target_line_no, inside_target_method: inside_target_method)
    end
  end

  def self.evaluate_default_value_node(node)
    case node.type
    when :LIT, :STR
      node.children[0] # Direct value
    else
      # Simplification: For complex types, further handling would be needed
      "complex value"
    end
  end
end

defaults = MethodAstIntrospector.extract_method_ast_and_defaults(Rules, :method_with_defaults)
puts defaults.inspect
