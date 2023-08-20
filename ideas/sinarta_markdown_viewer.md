To convert a file in the markdown format into an HTML file in Ruby, I would use the 'kramdown' gem. This gem provides a simple and efficient way to parse markdown and generate HTML output.

To show this HTML file to the user via a Sinatra web application, you can follow these steps:

1. Firstly, make sure you have the 'kramdown' gem installed in your project by adding it to your Gemfile or installing it via the command: `gem install kramdown`.

2. In your Sinatra web application, require the 'kramdown' gem:

```ruby
require 'kramdown'
```

3. Create a route in your Sinatra application to handle the markdown file conversion and render the resulting HTML file:

```ruby
get '/convert-markdown' do
  markdown_content = File.read('path/to/markdown-file.md') # Read the markdown file

  html_content = Kramdown::Document.new(markdown_content).to_html # Convert markdown to HTML

  content_type :html # Set the response content type to HTML

  html_content # Return the HTML content
end
```

4. Start your Sinatra application, and you can now access the `/convert-markdown` route to get the HTML file generated from the markdown file.

To format the response as Markdown in this answer, I have used the following Markdown syntax:

```
```ruby
require 'kramdown'
```
```
