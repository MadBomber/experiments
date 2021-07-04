#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
# warn_indent: true
##########################################################
###
##  File: justprep.rb
##  Desc: A preprocessor for justfiles using "main.just"
##        Looks for keywords: import include require with
##        followed by a file name or path.
##
##        It looks for a file "main.just" in the current directory.
##        If it does not exist, does nothing.  Otherwise it reviews
##        the file for the KEYWORDS.  When found it inserts the
##        content of the specified file into that position.  The
##        final text is written out to the "justfile" for processing
##        with the "just" tool.
##
##        There is NO ERROR checking.  including file names/paths
##        are assume to have to space characters.
##
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

KEYWORDS  = %w[ import include require with ]
BASEFILE  = 'justfile'
MAINFILE  = 'main.just'

require 'pathname'

######################################################
# Local methods

# review the text looking for module references
def find_modules(text)
  modules = []

  KEYWORDS.each do |keyword|
    modules << text.select{|x| x.start_with? "#{keyword} "}
  end

  return modules.flatten!
end


# somg;e-level inclusion
def include_content_from(file_name)
  file = Pathname.pwd + file_name
  content  = []
  content << "\n# #{file_name} >>>"
  content << file.readlines.map{|x| x.chomp} # TODO: support recursion??
  content << "# <<< #{file_name}\n"

  return content.flatten
end

######################################################
# Main

cwd       = Pathname.pwd
basefile  = cwd + BASEFILE
mainfile  = cwd + MAINFILE

exit(0) unless mainfile.exist?

text = mainfile.readlines.map{|x| x.chomp} # drop the line ending from each line

modules = find_modules text

if modules.empty?
  basefile.write text
  exit(0)
end

modules.each do |a_line|
  an_index        = text.index a_line
  parts           = a_line.split
  text[an_index]  = include_content_from parts.last
end

basefile.write text.flatten!.join "\n"
