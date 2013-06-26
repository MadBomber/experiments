#!/usr/bin/env ruby
###################################################
###
##  File: replace_stuff.rb
##  Desc: Replace $marker$ things inside a docx file with new stuff
#

require 'awesome_print'
require 'pathname'
require 'date'

# FIXME: This gem does not always work.
#        Use docx_templater instead.
require 'docx_replace'

doc = DocxReplace::Doc.new("data/daily_devotional_template.docx", "data")


doc.replace("$meditation_date$",      Date.today.to_s)
doc.replace("$title$",                "An article title")
doc.replace("$long_reading$",         "Read for a long time")
doc.replace("$quoted_scripture$",     "Turn Left at the second house and go three blocks.")
doc.replace("$citation$",             "Maps 1:1")

# FIXME: How do you insert multiple paragraphs?
doc.replace("$body_text$",            "How many times have you been lost?\none\ntwo\nthree?")

doc.replace("$prayer$",               "Where am I?")
doc.replace("$tought_for_the_day$",   "Where ever you go; there you are")
doc.replace("$link2life$",            "Always take a map")
doc.replace("$author$",               'Dewayne VanHoozer')
doc.replace("$author_database_id$",   "0")
doc.replace("$prayer_focus$",         "The focus of a prayer")
doc.replace("$category$",             "sample")


doc.commit(File.new('tdv.docx','w'))
