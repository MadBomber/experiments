#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
# warn_indent: true
##########################################################
###
##  File: info2json.rb
##  Desc: Convert the INFO text files into JSON
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require_relative 'sermon'

require 'amazing_print'
require 'pathname'

require 'debug_me'
include DebugMe

NAS_SERMON_ARCHIVE = Pathname.new '/Volumes/share/bellaire_baptist/sermon_archive'

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

    begin
      sermon[key] = value
    rescue => e
      debug_me{[ :e, 'info_filepath.basename.to_s', :entry, :key ]}
    end
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


info_filepaths  = NAS_SERMON_ARCHIVE
                    .children
                    .select{|c| '.info' == c.extname}

info_filepaths.each do |info_filepath|
  info_filename = info_filepath.basename.to_s
  json_filename = info_filename.gsub('.info', '.json')
  json_filepath = NAS_SERMON_ARCHIVE + json_filename

  puts info_filename

  sermon  = info2sermon(info_filepath)

  json_filepath.write sermon.to_json
end


__END__

Date:       2020-08-02 Sunday

series:

Title:      What if you had one year to live?

Speaker:    Dr. Randy Harper

Media File Name: 0e10744352_1596471129_sermon-cutdown-8-2-20.mp4

Website Source Filename: sermons-2020-08.meta

Errors: File does not exist: 0e10744352_1596471129_sermon-cutdown-8-2-20.mp4

Notes:
