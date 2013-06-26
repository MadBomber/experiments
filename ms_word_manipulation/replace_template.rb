#!/usr/bin/env ruby
###################################################
###
##  File: replace_template.rb
##  Desc: Replace ||marker|| things inside a docx file with new stuff
#

require 'date'

require 'docx_templater'

data_hash =
  {
    :meditation_date      =>  Date.today.to_s,
    :title                =>  "An article title",
    :long_reading         =>  "Read for a long time",
    :quoted_scripture     =>  "Turn Left at the second house and go three blocks.",
    :citation             =>  "Maps 1:1",

    :body_text            =>  "How many times have you been lost?\none\ntwo\nthree?",

    :prayer               =>  "Where am I?",
    :tought_for_the_day   =>  "Where ever you go; there you are",
    :link2life            =>  "Always take a map",
    :author               =>  'Dewayne VanHoozer',
    :author_database_id   =>  "0",
    :prayer_focus         =>  "The focus of a prayer",
    :category             =>  "sample"
  }


buffer = DocxTemplater.new.replace_file_with_content('data/dd_template.docx', data_hash)

File.open("tdv.docx", "wb") {|f| f.write(buffer.string) }

