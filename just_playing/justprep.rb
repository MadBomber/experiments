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
def include_content_from(file_path)
  content   = []
  content  << "\n# >>> #{file_path}"
  content  << file_path.readlines.map{|x| x.chomp} # TODO: support recursion??
  content  << "# <<< #{file_path}\n"

  return content.flatten
end


# look for first occurace of mainfile
def just_find_it(here=Pathname.pwd)
  mainfile = here + MAINFILE
  return mainfile if mainfile.exist?
  return nil if here == here.parent
  return just_find_it(here.parent)
end


# use an external shell to expand system environment variables
def expand_file_path(a_path_string)
  if a_path_string.start_with? '~'
    a_path_string = "${HOME}" + a_path_string[1, a_path_string.size-1]
  end

  a_path_string = `echo "#{a_path_string}"`.chomp

  return a_path_string
end


######################################################
# Main

mainfile  = just_find_it

exit(0) if mainfile.nil?

basefile  = mainfile.parent + BASEFILE

text = mainfile.readlines.map{|x| x.chomp} # drop the line ending from each line

modules = find_modules text

if modules.empty?
  basefile.write text
  exit(0)
end

modules.each do |a_line|
  an_index        = text.index a_line
  begin_filename  = a_line.index(' ')
  module_filename = a_line[begin_filename, a_line.size - begin_filename].strip

  if module_filename.empty?
    STDERR.puts "#{an_index}: #{a_line}"
    STDERR.puts "ERROR: No path/to/file was provided"
    next
  end

  if module_filename.include?('~')  || module_filename.include?('$')
    module_filename = expand_file_path(module_filename)
  end

  module_path     = Pathname.new(module_filename)

  if module_path.relative?
    module_path = mainfile.parent + module_path
  end

  if module_path.exist?
    text[an_index]  = include_content_from(module_path)
  else
    STDERR.puts "#{an_index}: #{a_line}"
    STDERR.puts "| ERROR: File Does Not Exist - #{module_path}"
  end
end

basefile.write text.flatten!.join "\n"
