#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
# warn_indent: true
##########################################################
###
##  File: info2html.rb
##  Desc: Convert the INFO text files into HTML
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#


require 'amazing_print'
require 'pathname'

require 'debug_me'
include DebugMe


Sermon = Struct.new(  :source, :speaker, :date,
                      :title,   :series, :filename,
                      :errors, :notes)


LABEL2KEY = {
  "Date"                    => :date,
  "Series"                  => :series,
  "Speaker"                 => :speaker,
  "Title"                   => :title,
  "Media File Name"         => :filename,
  "Website Source Filename" => :source,
  "Errors"                  => :errors,
  "Notes"                   => :notes,
}

key2heading = {}

LABEL2KEY.each_pair do |k,v|
  key2heading[v] = k
end

KEY2HEADING = key2heading

######################################################
# Local methods


def info2sermon(info_filepath)
  lines = info_filepath.readlines.map{|x| x.strip}.reject{|x| x.empty?}

  sermon = Sermon.new

  lines.each do |entry|
    parts       = entry.split(':')
    label       = parts.shift
    value       = parts.join(':').strip
    key         = LABEL2KEY[label]

    sermon[key] = value
  end

  return sermon
end



######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

here = Pathname.pwd

info_filepaths  = here
                    .children
                    .select{|c| '.info' == c.extname}
                    .reject{|c| c.basename.to_s.include?('problem')}
                    .sort_by{|c| c.basename.to_s}
                    .reverse

html_filename = "index.html"
html_filepath = here + html_filename

keys      = Sermon.new().to_h.keys
headings  = LABEL2KEY.keys.map{|h| "<td>#{h}</td>"}.join("\n")

html = <<~HTML
<html>
  <head>
    <title>Sermon Archive Index</title>
  </head>
  <body>
    <table><caption>Sermon Archive Index</caption>
      <thead>
        <tr>
          #{headings}
        </tr>
      </thead>
      <tbody>
HTML


info_filepaths.each do |info_filepath|
  html += "<tr>\n"

  sermon  = info2sermon(info_filepath)
  keys    = LABEL2KEY.values
  keys.each do |key|
    if :filename == key && !sermon.filename.empty?
      html += "<td><a href=#{sermon[key]}>#{sermon[key]}</a></td>"
    else
      html += "<td>#{sermon[key]}</td>\n"
    end
  end

  html += "</tr>\n"
end


html += <<~TABLE
      </tbody>
    </table>
  </body>
</html>

TABLE


puts html

html_filepath.write html


__END__

Date:       2020-08-02 Sunday

series:

Title:      What if you had one year to live?

Speaker:    Dr. Randy Harper

Media File Name: 0e10744352_1596471129_sermon-cutdown-8-2-20.mp4

Website Source Filename: sermons-2020-08.meta

Errors: File does not exist: 0e10744352_1596471129_sermon-cutdown-8-2-20.mp4

Notes:
