#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
# warn_indent: true
##########################################################
###
##  File: getem.rb
##  Desc: Grap Videos from websites
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

URL = "http://bellairebaptist.org/sermons/month/"
MONTHS = %w[ 1-2016  1-2017  1-2018  1-2019  1-2020  10-2015  10-2016  10-2017  10-2018  11-2015  11-2016  11-2017  11-2018  12-2015  12-2016  12-2017  12-2018  2-2016  2-2017  2-2018  2-2020  3-2016  3-2017  3-2018  3-2019  3-2020  4-2016  4-2017  4-2018  5-2015  5-2016  5-2017  6-2015  6-2016  6-2017  6-2018  6-2020  7-2015  7-2016  7-2017  7-2018  7-2020  8-2015  8-2016  8-2017  8-2018  8-2019  8-2020  9-2015  9-2016  9-2017  9-2018  9-2019  9-2020  ]

require 'date'
require "json"
require "ferrum"
require 'mhtml'


require 'amazing_print'

require 'debug_me'
include DebugMe






######################################################
# Local methods

def yyyy_mm(month_dash_year)
  Date.parse("28-"+month_dash_year).to_s[0..6]
end


def yyyy_mm_dd(a_date_string)
  Date.parse(a_date_string).to_s[0..9]
end


def save_as_mhtml(xxx=0)
  yyy = xxx.dup

  browser   = Ferrum::Browser.new(
                headless:     true,
                timeout:      15,
                window_size:  [1920, 1080]
              )

  MONTHS[xxx..].each do |m_yyyy|
    print "Processing (#{yyy}) #{m_yyyy} ... "
    begin
      error = false
      browser.go_to(URL+m_yyyy)
      browser.network.wait_for_idle    # browser.screenshot(full: true, path: "screenshot-#{yyyy_mm(m_yyyy)}.png")
      browser.mhtml(path: "sermons-#{yyyy_mm(m_yyyy)}.mhtml")
    rescue => e
      error = true
      puts e
    end

    puts 'done' unless error

    yyy += 1

    if 0 == yyy%5
      puts
      puts "... sleeping ..."
      puts
      sleep 30
    end

  end

  browser.quit
end # def save_as_,html


def extract_html_create_txt
  here = Pathname.pwd

  mhtml_docs = here.children.select{|c| '.mhtml' == c.extname}

  mhtml_docs.each do |mhtml_doc|
    puts "Processing #{mhtml_doc.basename} ... "

    source  = File.open(mhtml_doc.basename.to_s).read
    doc     = Mhtml::RootDocument.new(source)
    subdoc  = doc.sub_docs[0]

    content_type      = subdoc.header('Content-Type')&.to_s&.split(' ')&.last
    content_location  = subdoc.header('Content-Location')&.to_s&.split(' ')&.last

    next unless content_type.include?('text/html')
    next unless content_location

    html_filename = mhtml_doc.basename.to_s.gsub('mhtml', 'html')
    html_filepath = here + html_filename
    txt_filename  = mhtml_doc.basename.to_s.gsub('mhtml', 'txt')
    txt_filepath  = here + txt_filename

    html_filepath.write(subdoc.body)


    system "touch #{txt_filepath}"
    system "html2text -width 4096 -ascii -nobs -links -o #{txt_filepath} #{html_filepath}"
  end
end # def extract_html_create_txt


def create_meta_and_ref_files
  here = Pathname.pwd

  txt_filepaths = here.children.select{|c| '.txt' == c.extname}

  txt_filepaths.each do |txt_filepath|
    txt_filename  = txt_filepath.basename.to_s
    yyyy_mm       = txt_filename.gsub('sermons-','').gsub('.txt','')

    puts "Processing #{yyyy_mm} in #{txt_filename} ... "

    lines = txt_filepath.read.split("\n")

    references_start = lines.index('* References *')

    references = lines[references_start..].join("\n")

    ref_filename = "sermons-#{yyyy_mm}.ref"
    ref_filepath = here + ref_filename

    ref_filepath.write references

    filter_by_end = 0
    references_start.times do |xxx|
      if lines[xxx].start_with? '[One of:'
        filter_by_end = xxx
        break
      end
    end

    sermons_meta_start  = filter_by_end + 1
    sermons_meta_end    = lines.index('For The Glory Of God.')-1


    sermons_meta = lines[sermons_meta_start..sermons_meta_end]

    meta_filename = "sermons-#{yyyy_mm}.meta"
    meta_filepath = here + meta_filename

    meta_filepath.write(sermons_meta.join("\n"))
  end
end # def create_meta_and_ref_files

######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

here          = Pathname.pwd
toc_filename  = 'sermons_archive_toc.txt'
toc_filepath  = here + toc_filename

sermon_filenames = toc_filepath.read.split("\n")

sermon_filenames.each do |filename|
  filepath = here + filename
  extension = filepath.extname

  puts "\n\nProcessing #{filename} ... "
  parts = filename.split('_')
  uuid  = parts[0..1].join("_")
  hits  =  `ag #{filename} *.ref`.split(":")

  ref_filename  = hits[0]
  ref_line      = hits[1]
  parts         = hits[2].split('.').map{|part| part.strip}
  reference     = "[#{parts.first}]"
  ref_href      = parts.last + ':' + hits[3]

  puts "  ref_filename: #{ref_filename}"
  puts "  reference:    #{reference}"
  puts "  more(#{hits.size}) ..." if hits.size > 4
end





__END__
