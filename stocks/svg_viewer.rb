#!/usr/bin/env ruby
# experiments/sinatra_examples/svg_viewer.rb
# builds on md_viewer.rb

# require 'kramdown'
# require 'nenv'
# require 'sinatra/base'

class Web < Sinatra::Base

  # Set the directory location
  set :markdown_directory, Nenv.home + '/Downloads'

  # Sinatra route to show a markdown file as html
  get '/md/:filename' do
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


  # Sinatra route to show a markdown file as html
  get '/svg/:filename' do
    # Get the file name from the URL parameter
    filename = params[:filename]

    # Check if the file exists in the specified directory
    if File.file?(File.join(settings.markdown_directory, filename))
      # Read the svg file
      svg_content = File.read(File.join(settings.markdown_directory, filename))

      # Convert the svg to HTML
      converted_html = <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>#{filename}</title>
        </head>
        <body>
          #{svg_content}
        </body>
        </html>
      HTML

      # Display the generated HTML
      content_type :html
      converted_html
    else
      # File not found error
      status 404
      "File not found: #{filename} in #{markdown_directory}"
    end
  end
end

# Start the Sinatra app
run Web

