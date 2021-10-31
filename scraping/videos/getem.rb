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


NAS_SERMON_ARCHIVE = Pathname.new '/Volumes/share/bellaire_baptist/sermon_archive'

Sermon = Struct.new(  :source, :speaker, :date,
                      :title,   :series, :filename,
                      :errors, :notes)



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



def associated_content_file_to_reference(debug: false)

  here              = Pathname.pwd
  toc_filename      = 'sermons_archive_toc.txt'
  toc_filepath      = here + toc_filename
  ref_xref          = {}
  sermon_filenames  = toc_filepath.read.split("\n")

  sermon_filenames.each do |filename|
    filepath = here + filename
    extension = filepath.extname

    puts "\n\nProcessing #{filename} ... "   if debug
    parts = filename.split('_')
    uuid  = parts[0..1].join("_")
    hits  = `ag #{filename} *.ref`.split(":")

    ref_filename  = hits[0]
    ref_line      = hits[1]
    parts         = hits[2].split('.').map{|part| part.strip}
    reference     = "[#{parts.first}]"
    ref_href      = parts.last + ':' + hits[3]

    if debug
      puts "  ref_filename: #{ref_filename}"
      puts "  reference:    #{reference}"
      puts "  more(#{hits.size}) ..." if hits.size > 4
    end

    unless ref_xref.has_key?(ref_filename)
      ref_xref[ref_filename] = {}
    end

    ref_xref[ref_filename][reference] = filename
  end

  return ref_xref
end


def create_info_file_for(sermons)
  here = Pathname.pwd

  sermons.each do |sermon|
    next if sermon.date.nil?

    unless sermon.date.is_a? Date
      ap sermon

      problem_count = 1
      filepath = here + "#{sermon.source}-problem-#{problem_count}.info"

      while filepath.exist? do
        problem_count += 1
        filepath = here + "#{sermon.source}-problem-#{problem_count}.info"
      end

      filepath.write sermon.ai(plain: true)

      next
    end

    if sermon.title.is_a? Array
      if 2 == sermon.title.size
        sermon.series = sermon.title.last
        sermon.title  = sermon.title.first
      else
        sermon.title  = sermon.title.join("; ")
      end
    end

    info_basename = "sermons-#{sermon.date.to_s}-#{sermon.date.strftime('%a').downcase}"
    info_filename = "#{info_basename}.info"
    info_filepath = here + info_filename

    if sermon.errors.nil?  &&  !sermon.filename.nil?
      media_filename  = sermon.filename
      media_filepath  = NAS_SERMON_ARCHIVE + media_filename
      media_extname   = media_filepath.extname

      new_media_filename = info_basename + media_extname
      new_media_filepath = NAS_SERMON_ARCHIVE + new_media_filename

      sermon.notes = "#{new_media_filename} was originally #{media_filename}"

      `mv #{media_filepath} #{new_media_filepath}`
      sermon.filename = new_media_filename
    end

    info_filepath.write <<~END_OF_SERMON_INFO
      Date:       #{sermon.date} #{sermon.date.strftime('%A')}

      Series:     #{sermon.series}

      Title:      #{sermon.title}

      Speaker:    #{sermon.speaker}

      Media File Name: #{sermon.filename}

      Website Source Filename: #{sermon.source}

      Errors: #{sermon.errors}

      Notes:  #{sermon.notes}
    END_OF_SERMON_INFO
  end

end



def rewrite_meta(ref_db, debug: false)

  here            = Pathname.pwd
  ref_regex       = /\[(\d+)\]/

  tags  = [
            "uploaded%2F",
            "ssl.cf2.rackcdn.com%2Fh264-720%2F"
          ]

  content_file_end_tag    = "&amp;"

  meta_filepaths  = here.children.select{|c| '.meta' == c.extname}


  file_count = 0

  meta_filepaths.each do |meta_filepath|
    meta_filename = meta_filepath.basename.to_s
    ref_filename  = meta_filename.gsub('.meta', '.ref')
    ref_filepath  = here + ref_filename

    meta_lines    = meta_filepath.readlines.map{|x| x.strip}
    ref_lines     = ref_filepath.readlines.map{|x| x.strip}

    # ap meta_lines,  plain: true, indent: 2, index: false
    # ap ref_lines,   plain: true, indent: 2, index: true

    meta_lines.each_with_index do |meta_line, meta_index|
      dc = meta_line.downcase

      if dc == "**** Sunday At Bellaire ****".downcase ||
          dc.start_with?('[')
        meta_lines[meta_index] = Sermon.new(meta_filename)
        next
      end

      parts = dc.split(' ')

      if 4 == parts.last.size  &&  parts.last.start_with?('20')
        sermon_date = Date.parse meta_line
        sermon = Sermon.new(meta_filename)
        sermon.date = sermon_date

        meta_lines[meta_index] = sermon
        next
      end


      if dc.start_with?('keyword')
        meta_lines[meta_index] = '__END__'
        next
      end


      if dc.start_with?('****')
        # Its either a title or a series; can't tell the difference
        sermon        = Sermon.new(meta_filename)
        sermon_title  = meta_line.gsub('*', ' ').strip

        if sermon_title.include?('[')
          xxx           = sermon_title.index('[')
          sermon_title  = sermon_title[0,xxx].strip
        end

        sermon.title            = sermon_title.gsub('_', ' ')
        meta_lines[meta_index]  = sermon

        next
      end


      next unless dc.end_with?(']') || dc.end_with?('] ****')

      if dc.start_with?('speaker')
        sermon          = Sermon.new(meta_filename)
        sermon_speaker  = meta_line.split(":")[1].split('[').first.strip.gsub('_', ' ')
        sermon.speaker  = sermon_speaker
        meta_lines[meta_index] = sermon
        meta_index_next = meta_index + 1
        unless meta_index_next >= meta_lines.size
          unless meta_lines[meta_index_next].downcase.start_with?('keyword')
            meta_lines.insert(meta_index_next, '__END__')
          end
        end

        next
      end


      ref_index = meta_lines[meta_index].match(ref_regex)[1].to_i


      ref_line =  ref_lines[ref_index]


      found_content_tag = false

      tags.each do |content_file_start_tag|
        if ref_line.include?(content_file_start_tag)
          found_content_tag = true
          start_index     = ref_line.index(content_file_start_tag) + content_file_start_tag.size + 4
          content_length  = ref_line[start_index..].index(content_file_end_tag)

          ref_line    = ref_line[start_index, content_length]

          sermon_filename = ref_line.dup

          sermon = Sermon.new(meta_filename)
          sermon.filename = sermon_filename

          sermon_filepath = NAS_SERMON_ARCHIVE + sermon_filename

          unless sermon_filepath.exist?
            sermon.errors = "File does not exist: #{sermon.filename}"
          end

          meta_lines[meta_index] = sermon
        end
      end

      next if found_content_tag

      meta_lines[meta_index] += "\t" + ref_line

    end

    meta_lines << '__END__' unless '__END__' == meta_lines.last

    ap meta_lines if debug

    sermons = build_sermons(meta_lines.compact.reverse)

    create_info_file_for(sermons)

    puts "="*65 # if debug

    file_count += 1

    # break if file_count > 15
  end
end


def combine_sermons(this_sermon, entry)
  return this_sermon unless entry.is_a? Sermon

  keys = entry.to_h.keys

  keys.each do |key|
    next if entry[key].nil?

    if this_sermon[key].nil?
      this_sermon[key] = entry[key]
    else
      unless this_sermon[key] == entry[key]
        this_sermon[key] = Array(this_sermon[key])
        this_sermon[key] << entry[key]
      end
    end
  end

  return this_sermon
end


def build_sermons(an_array, debug: false)
  sermons = []

  an_array.each do |entry|
    if '__END__' == entry
      sermons << Sermon.new
    end

    sermon_index = sermons.size - 1

    sermons[sermon_index] = combine_sermons(sermons[sermon_index], entry)
  end

  return sermons
end


######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end


# ref_db = associated_content_file_to_reference
# ap ref_db

# rewrite_meta(ref_db)


here = NAS_SERMON_ARCHIVE

mp4_filepaths = here.children.select{|c| '.mp4' == c.extname}

mp4_filepaths.each do |mp4_filepath|
  mp4_filename  = mp4_filepath.basename.to_s
  info_filename = mp4_filename.gsub('.mp4', '.info')
  info_filepath = here + info_filename

  info = info_filepath.read

  next if info.include? mp4_filename

  print  info_filename + "  "
end

puts


__END__
