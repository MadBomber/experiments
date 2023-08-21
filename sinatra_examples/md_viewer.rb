#!/usr/bin/env ruby
# ideas/md_viewer.rb

require 'sinatra'
require 'kramdown'
require 'nenv'

# class MdViewer < Sinatra::Application

  # Set the directory location
  set :markdown_directory, Nenv.home + '/Downloads'

  # Sinatra route to show a markdown file as html
  get '/show/:filename' do
    # Get the file name from the URL parameter
    filename = params[:filename]

    # Check if the file exists in the specified directory
    if File.file?(File.join(settings.markdown_directory, filename))
      # Read the markdown file
      markdown_content = File.read(File.join(settings.markdown_directory, filename))

      # Convert the markdown to HTML using kramdown
      converted_html = Kramdown::Document.new(markdown_content).to_html

      # Display the generated HTML
      content_type :html
      converted_html
    else
      # File not found error
      status 404
      "File not found: #{filename} in #{markdown_directory}"
    end
  end

# end

# Start the Sinatra app
# run MdViewer

