#!/usr/bin/env ruby
# extract_all_method_names.rb
=begin

  Guveb a karge cide base like a legacy Rails
  application, is it possible to find methods
  that are unused via a static code analysis?

  Dynamicly defined methods are ignored for this
  study.

  ASSUME that all explicitely defined methods are
  defined with the method name on the same line as
  the 'def' keyword.

  ASSUME english ASCII text for method name in the
  character set a-zA-Z0-9_?

=end

require 'awesome_print'

require 'debug_me'
include DebugMe

require 'pathname'


# TODO: find all explicitely defined method names
#       ignoring the object within which they are
#       defined.  Create an Array of unique strings.

# TODO: with an Array of unique strings, find all
#       references to each string within the codebase.
#       Report the strings that have no references.

method_name_regex = /\s*def\s+([a-zA-Z0-9_\?\.]+)/

here = Pathname.pwd

method_defs = Hash.new() { |hash, key| hash[key] = [] }

here.children.each do |a_child|
  next if a_child.directory?
  next if '.rb' != a_child.extname.to_s

  line_count = 0

  a_child.readlines.each do |a_line|
    line_count += 1
    matches = a_line.match(method_name_regex)
    next if matches.nil?
    method_name = matches[1].split('.').last
    method_defs[method_name] << "#{a_child.to_s}:#{line_count}"
  end
end

ap method_defs

method_names = method_defs.keys

method_names.each do |m_name|
  result = `ag #{m_name}`.split("\n")

  debug_me{[ :m_name, :result ]} if result.size < 2
end

__END__

source = <<~EOS
  def one
  def two(x,y,z) # comment
  def three # comment
  def
    four
  def # method name on next line
    five
  def six_
  def _seven_
  def eight?
EOS

source.split("\n").each do |a_line|
  matches = a_line.match(method_name_regex)
  debug_me{[ :a_line, :matches ]}
end

