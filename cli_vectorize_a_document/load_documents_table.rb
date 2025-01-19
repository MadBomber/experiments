#!/usr/bin/env ruby
# scripts/load_docutmes_table.rb

require 'pathname'
require 'ruby-progressbar'  # Ruby/ProgressBar is a flexible text progress bar library for Ruby.

require_relative 'lib/database_connection.rb'
require_relative 'lib/models'

repo_root = Pathname.new(ENV.fetch('RR', '__dir__/..'))
docs_dir  = repo_root + 'docs'

txt_files = docs_dir.children.select{|c| '.txt' == c.extname }

txt_files.each do |filepath|
  basename = filepath.basename
  puts "adding #{basename} ..."
  
  progressbar = ProgressBar.create(
    title: 'Lines',
    total: filepath.each_line.count,
    format: '%t: [%B] %c/%C %j%% %e',
    output: STDERR
  )

  doc = Document.create(
          filename: filepath.to_s,
          title:    basename.to_s.gsub('.txt','')
        )
  filepath.readlines.each_with_index do |text, line|
    progressbar.increment

    doc.contents  <<  Content.create(
                        text: text,
                        line_number: line + 1
                      )
  end

  progressbar.finish
end