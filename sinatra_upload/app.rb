#!/usr/bin/env ruby
#######################################################################
###
##  File: sinatra_uploader/app.rb
##  Desc: uploads MS Word DOCX files
#

require 'sinatra'
require 'haml'

# Handle GET-request (Show the upload form)
get "/upload" do
  haml :upload
end

# Handle POST-request (Receive and save the uploaded file)
post "/upload" do

  show_char_styles  = ( '1' == params['show_char_styles'] )

  docx_pathname = Pathname.new('uploads') + params['myfile'][:filename]
  html_pathname = Pathname.new(docx_pathname.to_s + '.html')
  erb_pathname  = Pathname.new(docx_pathname.to_s + '.erb')

  if '.docx' == docx_pathname.extname.downcase

    File.open(docx_pathname.to_s, "w") do |f|
      f.write(params['myfile'][:tempfile].read)
    end

    erb :success

    system "docx_draft_layout.rb --html #{show_char_styles ? '' : '--no-char' } '#{docx_pathname}'"

    system "mv '#{html_pathname}' '#{erb_pathname}'"

    erb File.open("#{erb_pathname}","r").read

  else

    haml :not_docx_error

  end

end # end of post "/upload" do

