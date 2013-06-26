#!/usr/bin/env ruby
###################################################
###
##  File: docx_edit.rb
##  Desc: Replace $marker$ things inside a docx file with new stuff
#

require 'awesome_print'
require 'date'

# SMELL: Looks like same as docx_replace
#        does not work
require 'docxedit'

doc = DocxEdit::Docx.new('data/daily_devotional_template.docx')

puts doc.contains? /meditation_date/  #return true if regexp is match in one of the document xml node


doc.replace(/meditation_date/,      Date.today.to_s)
doc.replace("$title$",                "An article title")
doc.replace("$long_reading$",         "Read for a long time")
doc.replace("$quoted_scripture$",     "Turn Left at the second house and go three blocks.")
doc.replace("$citation$",             "Maps 1:1")

# FIXME: How do you insert multiple paragraphs?
#doc.replace("$body_text$",            "How many times have you been lost?\none\ntwo\nthree?")


block = doc.find_block_with_content("body_text") #return a ContentBlock object

ap block

# insert a new block of text before block
# FIXME: insert_block does not work
#doc.insert_block(:before, block, DocxEdit::ContentBlock.new("<w:p><w:r>zero</w:r></w:p>", "0") )
#doc.insert_block(:before, block, DocxEdit::ContentBlock.new("<w:p><w:r>one</w:r></w:p>", "1") )
#doc.insert_block(:before, block, DocxEdit::ContentBlock.new("<w:p><w:r>two</w:r></w:p>", "2") )
#doc.insert_block(:before, block, DocxEdit::ContentBlock.new("<w:p><w:r>three?</w:r></w:p>", "3?") )

# FIXME: same problem method xml not defined
#doc.remove_block(block)

doc.replace("$prayer$",               "Where am I?")
doc.replace("$tought_for_the_day$",   "Where ever you go; there you are")
doc.replace("$link2life$",            "Always take a map")
doc.replace("$author$",               'Dewayne VanHoozer')
doc.replace("$author_database_id$",   "0")
doc.replace("$prayer_focus$",         "The focus of a prayer")
doc.replace("$category$",             "sample")


# FIXME: Nothing worked
doc.commit  # (File.new('tdv.docx','w'))




