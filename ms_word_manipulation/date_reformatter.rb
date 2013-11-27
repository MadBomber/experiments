#!/usr/bin/env ruby
###################################################
###
##  File: date_reformatter.rb
##  Desc: Replace the publication date from the form YYYY-MM-DD
##        to the form DOW MMM DD YYYY
#

require 'awesome_print'
require 'pathname'
require 'date'

pgm_name = Pathname.new(__FILE__).basename

# FIXME: This gem does not always work.
#        Use docx_templater instead.
require 'docx_replace'

usage_str = <<-EOS

USAGE: #{pgm_name} year in_dir out_dir

Where:

	year			The publication year in the form YYYY of the meditations

	in_dir		A directory containing MS Word files (*.docx) whose
						filenames have the standard DDG convention with the
						pattern YYYYMMDD representing the publication date of the
						meditation
	
	out_dir		A directory into which the modified files are placed

EOS

if ARGV.empty?  or  ARGV.include?('-h')  or  ARGV.include?('--help')
	puts usage_str
	exit
end

unless 3 == ARGV.size
	puts usage_str
	exit
end

year 		= ARGV[0]
in_dir	= Pathname.new ARGV[1]
out_dir	= Pathname.new ARGV[2]

error_count = 0

unless 4 == year.length  and  '20' == year[0,2]
	puts "ERROR: year should be 20yy format, not '#{year}'"
	error_count += 1
end	

unless in_dir.exist?  and  in_dir.directory?
	puts "ERROR: Not a valid directory: '#{in_dir}'"
	error_count += 1
end

unless out_dir.exist?  and  out_dir.directory?
	puts "ERROR: Not a valid directory: '#{out_dir}'"
	error_count += 1
end

if in_dir == out_dir
	puts "ERROR: out_dir must not be the same as in_dir"
	error_count += 1
end



if 	error_count > 0
	puts usage_str
	exit
end




in_dir.children.each do |c|

	if 	c.directory?  									or
	  	'.docx' != c.extname.downcase  	or
	    !c.to_s.include?(year)  				or
	    'Backup' == c.basename.to_s[0,6]
		next
	end

	docx_filename 		= c.to_s
	docx_basename			= c.basename.to_s
	docx_filename_out	= (out_dir + c.basename).to_s

	x = docx_basename.index(year)

	next if x.nil?

	#puts "#{docx_filename} .... "

	f1 = docx_basename[x,8]

	ok = f1 == f1.match(/[0-9]+/).to_s

	next unless ok

	print "."

	f2 = f1[0,4]+'-'+f1[4,2]+'-'+f1[6,2]

	#puts f2

	d8 = Date.parse( f2 ).strftime("%^a %^b %d %Y")

	#puts "  Replacing:  '#{f2}'  with  '#{d8}'"

	doc 	= DocxReplace::Doc.new(docx_filename, out_dir.to_s)

	xyzzy = doc.inspect

	if xyzzy.include?(f2)
		doc.replace( f2, d8 )
		doc.commit(File.new(docx_filename_out,'w'))
	else
		puts "\nWARNING: filename / internal date mis-matched."
		puts "         #{docx_filename}"
	end

end	# of ARGV.each do |docx_filename|

puts
