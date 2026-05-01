#!/usr/bin/env ruby
# experiments/svg/filesystem_svg_image_generator.rb

require 'nokogiri'
require 'optparse'

class FileSystemSVGGenerator
  def initialize(base_dir, levels, include_files)
    @base_dir = base_dir
    @levels = levels
    @include_files = include_files
    @svg = Nokogiri::XML::Builder.new { |xml| xml.svg }
    @x = 0
    @y = 10
    @max_x = 0
  end

  def generate
    draw_directory(@base_dir, 1)
    @svg.to_xml
  end

  private

  def draw_directory(path, level)
    return if level > @levels

    Dir.foreach(path) do |entry|
      next if ['.', '..'].include?(entry)

      full_path = File.join(path, entry)
      if File.directory?(full_path)
        draw_label(entry, @x, @y)
        @y += 20
        @x += 20
        draw_directory(full_path, level + 1)
        @x -= 20
      elsif @include_files && File.file?(full_path) 
        draw_label(entry, @x, @y)
        @y += 20
      end

      @max_x = [@max_x, @x].max
    end
  end

  def draw_label(text, x, y)
    @svg.doc.root.add_child(
      Nokogiri::XML::Node.new('text', @svg.doc).tap do |node|
        node['x'] = x
        node['y'] = y
        node['font-family'] = 'Arial'
        node['font-size'] = '10'
        node.content = text
      end
    )
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: filesystem_svg.rb [options]"

  opts.on("-d", "--directory DIR", "Base directory path") do |d|
    options[:directory] = d
  end

  opts.on("-l", "--levels LEVELS", Integer, "Number of levels to include") do |l|
    options[:levels] = l
  end

  opts.on("-f", "--[no-]files", "Include files in the output image") do |f|
    options[:files] = f
  end
end.parse!

raise OptionParser::MissingArgument if options[:directory].nil? || options[:levels].nil?

svg_generator = FileSystemSVGGenerator.new(options[:directory], options[:levels], options[:files])
svg_content = svg_generator.generate

# Writing the SVG file.
File.open('filesystem.svg', 'w') { |file| file.write(svg_content) }

puts 'SVG file created: filesystem.svg'

