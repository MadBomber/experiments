#!/usr/bin/env ruby
###################################################
###
##  File: docx_draft_style.rb
##  Desc: Displays the paragraph style and contents of an MS Word *.docx file
#

require 'awesome_print'

require 'pathname'

require 'docx'
require 'word_wrapper'

style_width   = 20
line_width    = 4 * style_width

if '--html' == ARGV.first
  html_desired = true
  ARGV.shift
else
  html_desired = false
end

if '--no-char' == ARGV.first
  show_char_styles  = false
  ARGV.shift
else
  show_char_styles  = true
end

if ARGV.empty? or ARGV.first == "-h" or ARGV.first == "--help"
  puts
  puts "Usage: docx_draft_style.rb [options] MS_WORD_DOCX++"
  puts
  puts "  Where:"
  puts "    MS_WORD_DOCX++    is one or more Microsoft Word DOCX filenames"
  puts
  puts "    options are:"
  puts
  puts "      -h or --help    This usage message is produced"
  puts "      --html          Produces an HTML file for each input file"
  puts "      --no-char       Do not show character styles within content"
  puts
  exit
end


class String
  def wrap_with_style(style, html_preformatted = false)
    html_preformatted ? "&lt;#{style}&gt;" + self + "&lt;/#{style}&gt;" : "<#{style}>" + self + "</#{style}>"
  end
end # if class String




# SMELL: This returns a string in which the spaces have been squeezed out

def paragraph_style(para)

  begin
    style_element = para.node.children.children.first.attributes.first.last
    #ap style_element
    style_element.value.to_s
  rescue Exception => e
    #puts "ERROR: #{e}"
    #ap para.node
    "Normal"
  end

end # of def paragraph_style(para)


# A apragraph consists of one or more text_runs
# A paragraph has a style
# A text_run has a consistent style

def paragraph_contents(para, html = false, char_style = true)
  # ap para

  contents_string = ""

  para.text_runs.each do |tr|

    begin
      name    = tr.node.children[0].children[0].name
    rescue Exception => e
      #puts "ERROR: #{e}"
      #ap tr.node.children[0]  # .children[0]
      #style = "text"
      name    = tr.node.children[0].name
    end

    if 'rStyle' == name
      style   = tr.node.children[0].children[0].attributes.first.last.value
    elsif 'text' == name
      style   = nil
    else
      style   = name
    end

# SMELL: The TAB character is implemented as a character style; this code
#        does not take into account tab stops, etc.  May want to insert some
#        spaces or let the tab style through regardless the value of char_style

    if char_style # or 'tab' == style
    contents_string += style.nil? ? tr.text : tr.text.wrap_with_style(style, html)
    else
      contents_string += tr.text
    end

  end # of para.text_runs.each do |tr|

  #para.to_s

  return contents_string

end # end of def paragraph_contents(para)


######################################################################
## Main Loop around the ARGV which should contain only file names

out_file  = STDOUT

ARGV.each do |param|

  given_document = Pathname.new(param)

  unless '.docx' == given_document.extname.downcase
    STDERR.puts
    STDERR.puts "WARNING: Not a *.docx file -- skipping."
    STDERR.puts "   File: #{given_document}"
    STDERR.puts
    next
  end

  d = Docx::Document.open(given_document.to_s)


  if html_desired

    html_pathname = given_document.dirname + ( given_document.basename.to_s + ".html" )
    out_file      = html_pathname.open("w")

    out_file.puts "<html><head><title>#{given_document}</title></head>"
    out_file.puts "<body>"
    out_file.puts "<pre>"
  end

  out_file.puts
  out_file.puts "MS Word (docx) File Name:  #{given_document}"
  out_file.puts "Draft Layout Generated on: #{Time.now}"
  out_file.puts "-"*(30+given_document.to_s.length)
  out_file.puts

  d.paragraphs.each do |para|
    style     = paragraph_style(para)
    contents  = paragraph_contents(para, html_desired, show_char_styles)

    out_file.print style+" "*(style_width > style.size ? style_width-style.size : 3)
    lines = WordWrapper::MinimumRaggedness.new(line_width, contents).wrap.split("\n")
    x=1
    lines.each do |a_line|
      out_file.puts a_line
      x-=1
      out_file.print " "*style_width unless x>0
    end
    out_file.puts

  end

  out_file.puts

  if html_desired
    out_file.puts "</pre>"
    out_file.puts "</body>"
    out_file.puts "</html>"
    #out_file.close
  end

end # end of ARGV.each do |param|
