#!/usr/bin/env ruby
# extractor.rb

require "parser/current"
require "unparser"

require "amazing_print"
require "debug_me"
include DebugMe

def extract_info(file_path)
  debug_me {
    [
      :file_path,
    ]
  }

  source = File.read(file_path)
  buffer = Parser::Source::Buffer.new("", 1)
  buffer.source = source
  parser = Parser::CurrentRuby.new
  ast = parser.parse(buffer)

  debug_me {
    [
      :ast,
    ]
  }

  result = []

  # Define a recursive method to traverse through the AST
  ast.traverse do |node|
    debug_me {
      [
        :node,
      ]
    }

    case node.type
    when :module
      module_name = node.children[0].to_s
      methods = []

      node.each_child(:def) do |method_node|
        method_name = method_node.children[0].to_s
        params = method_node.children[1].children.map(&:to_s)
        methods << { name: method_name, params: params }
      end

      result << { type: "Module", name: module_name, methods: methods }
    when :class
      class_name = node.children[0].to_s
      methods = []
      attributes = []

      node.each_child(:def) do |method_node|
        method_name = method_node.children[0].to_s
        params = method_node.children[1].children.map(&:to_s)
        methods << { name: method_name, params: params }
      end

      node.each_child(:attr_accessor) do |attr_node|
        attributes += attr_node.children.map(&:to_s)
      end
      node.each_child(:attr_reader) do |attr_node|
        attributes += attr_node.children.map(&:to_s)
      end
      node.each_child(:attr_writer) do |attr_node|
        attributes += attr_node.children.map(&:to_s)
      end

      result << { type: "Class", name: class_name, methods: methods, attributes: attributes }
    end
  end

  result
end

# Usage
file_path = ARGV[0]
extracted_info = extract_info(file_path)

debug_me {
  [
    :extracted_info,
  ]
}

extracted_info
