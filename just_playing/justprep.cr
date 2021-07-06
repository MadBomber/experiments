#!/usr/bin/env crystal
# encoding: utf-8
# frozen_string_literal: true
# warn_indent: true
##########################################################
###
# #  File: justprep.cr
# #  Desc: A preprocessor for justfiles using "main.just"
# #        Looks for keywords: import include require with
# #        followed by a file name or path.
##
# #        It looks for a file "main.just" in the current directory.
# #        If it does not exist, does nothing.  Otherwise it reviews
# #        the file for the KEYWORDS.  When found it inserts the
# #        content of the specified file into that position.  The
# #        final text is written out to the "justfile" for processing
# #        with the "just" tool.
##
# #        There is NO ERROR checking.  including file names/paths
# #        are assume to have to space characters.
##
# #  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require "file_utils"

KEYWORDS = %w[import include require with]
BASEFILE = "justfile"
MAINFILE = "main.just"

######################################################
# Local methods

# review the text looking for module references
def find_modules(main_text : Array(String | Array(String))) : Array(String)
  modules = Array(String).new

  KEYWORDS.each do |keyword|
    lines = main_text.select { |a_line| a_line.to_s.starts_with? "#{keyword} " }
    unless lines.empty?
      lines.each do |a_line|
        modules << a_line.to_s
      end
    end
  end

  return modules
end

# single-level inclusion
def include_content_from(file_path : String) : Array(String)
  file = File.open(file_path, "r")
  content = Array(String).new
  content << "\n# >>> #{file_path}"

  file.gets_to_end.split("\n").each do |a_line|
    content << a_line
  end

  content << "# <<< #{file_path}\n"

  file.close

  return content
end

# look for first occurace of mainfile
# returns nil when none are found.
def just_find_it(here = FileUtils.pwd) : String | Nil
  mainfile_path = here + "/" + MAINFILE
  return mainfile_path if File.exists?(mainfile_path)

  parts = here.split('/')
  parts.pop

  return nil if parts.empty?
  return just_find_it(parts.join('/'))
end

# use an external shell to expand system environment variables
def expand_file_path(a_path_string : String) : String
  if a_path_string.starts_with? '~'
    a_path_string = "${HOME}" + a_path_string[1, a_path_string.size - 1]
  end

  a_path_string = `echo "#{a_path_string}"`.chomp

  return a_path_string
end

######################################################
# Main

mainfile_path = just_find_it(FileUtils.pwd)

exit(0) if mainfile_path.nil?

basefile_path = mainfile_path.gsub(MAINFILE, BASEFILE)

mainfile = File.open(mainfile_path, "r")

basefile = File.new(basefile_path, "w")

text = Array(String | Array(String)).new

mainfile.gets_to_end.split("\n").each do |a_line|
  text << a_line
end

mainfile.close

modules = find_modules(text)

if modules.empty?
  basefile.puts text.join("\n")
  basefile.close
  exit(0)
end

modules.each do |a_line|
  an_index = text.index(a_line) # Should never be nil
  begin_filepath = a_line.index(' ')

  unless begin_filepath.nil?
    filepath_size = a_line.size - begin_filepath
    module_path = a_line[begin_filepath, filepath_size].strip
  end

  if module_path.nil? || 0 == module_path.size
    STDERR.puts "#{an_index}: #{a_line}"
    STDERR.puts "ERROR: No path/to/file was provided"
    next
  end

  if module_path.includes?('~') || module_path.includes?('$')
    module_path = expand_file_path(module_path)
  end

  unless module_path.starts_with?('/')
    module_path = mainfile_path.gsub(MAINFILE, module_path)
  end

  if File.exists?(module_path)
    text[an_index] = include_content_from(module_path) unless an_index.nil?
  else
    STDERR.puts "#{an_index}: #{a_line}"
    STDERR.puts "| ERROR: File Does Not Exist - #{module_path}"
  end
end

basefile.puts text.flatten.join "\n"
basefile.close
