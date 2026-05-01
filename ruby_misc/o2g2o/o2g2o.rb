#!/usr/bin/env ruby
# frozen_string_literal: true

# o2g2o - Obsidian to GitHub to Obsidian
#
# Converts internal hyperlink formats between Obsidian wikilinks
# and GitHub-flavored markdown links.
#
# Obsidian format:  [[Page Name]]  [[Page Name|Display Text]]  [[Page Name#Heading]]
# GitHub format:    [Page Name](page-name.md)  [Display Text](page-name.md#heading)
#
# Also handles embeds:
#   Obsidian: ![[image.png]]  ![[file.pdf|Alt text]]
#   GitHub:   ![image](image.png)  ![Alt text](file.pdf)

require 'optparse'
require 'pathname'
require 'fileutils'

class O2G2O
  OBSIDIAN_LINK  = /\[\[([^\]]+)\]\]/
  OBSIDIAN_EMBED = /!\[\[([^\]]+)\]\]/

  # Matches [text](relative-path.md) or [text](relative-path.md#heading)
  # Excludes URLs (http://, https://, ftp://, mailto:, etc.)
  GITHUB_LINK = /\[([^\]]+)\]\((?!https?:\/\/|ftp:\/\/|mailto:)([^)]+\.md(?:#[^)]*)?)\)/

  # Matches ![alt](relative-path) excluding URLs
  GITHUB_EMBED = /!\[([^\]]*)\]\((?!https?:\/\/|ftp:\/\/|mailto:)([^)]+\.(?:png|jpg|jpeg|gif|svg|webp|bmp|ico|tiff|pdf|mp4|webm|ogv|mp3|wav|ogg))\)/i

  def initialize(direction:, in_place: false, backup: false, output_dir: nil)
    @direction  = direction
    @in_place   = in_place
    @backup     = backup
    @output_dir = output_dir
  end

  def process_path(path)
    path = Pathname.new(path)

    unless path.exist?
      warn "Error: #{path} does not exist"
      exit 1
    end

    if path.directory?
      process_directory(path)
    elsif path.extname == '.md'
      process_file(path)
    else
      warn "Error: #{path} is not a markdown file"
      exit 1
    end
  end

  private

  def process_directory(dir)
    count = 0
    Dir.glob(dir.join('**', '*.md')).sort.each do |file|
      process_file(Pathname.new(file))
      count += 1
    end
    warn "Processed #{count} markdown file#{'s' unless count == 1}"
  end

  def process_file(file)
    content  = file.read
    original = content.dup

    converted = case @direction
                when :o2g then obsidian_to_github(content)
                when :g2o then github_to_obsidian(content)
                end

    if converted == original
      warn "  #{file} (no changes)"
      return
    end

    write_output(file, converted)
    warn "  #{file} (converted)"
  end

  def write_output(file, content)
    if @output_dir
      relative  = file.relative_path_from(Pathname.pwd) rescue file
      dest      = Pathname.new(@output_dir).join(relative)
      dest.dirname.mkpath
      dest.write(content)
    elsif @in_place
      FileUtils.cp(file, "#{file}.bak") if @backup
      file.write(content)
    else
      puts content
    end
  end

  # --- Obsidian → GitHub ---------------------------------------------------

  def obsidian_to_github(text)
    result = text.dup

    # Process embeds first (they start with !) so the link regex doesn't
    # partially match them.
    result.gsub!(OBSIDIAN_EMBED) do |_match|
      inner = Regexp.last_match(1)
      convert_embed_o2g(inner)
    end

    result.gsub!(OBSIDIAN_LINK) do |_match|
      inner = Regexp.last_match(1)
      convert_link_o2g(inner)
    end

    result
  end

  def convert_link_o2g(inner)
    # inner can be: "Page", "Page|Alias", "Page#Heading", "Page#Heading|Alias"
    if inner.include?('|')
      target, display = inner.split('|', 2)
    else
      target  = inner
      display = nil
    end

    if target.include?('#')
      page, heading = target.split('#', 2)
      slug_heading  = slugify(heading)
    else
      page    = target
      heading = nil
    end

    if page.empty?
      # [[#Heading]] - same-page anchor
      display ||= heading
      "[#{display}](##{slug_heading})"
    else
      slug_page = slugify(page)
      extension = page.match?(/\.\w+$/) ? '' : '.md'

      if heading
        display ||= "#{page}##{heading}"
        "[#{display}](#{slug_page}#{extension}##{slug_heading})"
      else
        display ||= page
        "[#{display}](#{slug_page}#{extension})"
      end
    end
  end

  def convert_embed_o2g(inner)
    if inner.include?('|')
      target, alt = inner.split('|', 2)
    else
      target = inner
      alt    = File.basename(target, File.extname(target))
    end

    slug_target = slugify(target)
    "![#{alt}](#{slug_target})"
  end

  # --- GitHub → Obsidian ---------------------------------------------------

  def github_to_obsidian(text)
    result = text.dup

    # Process embeds first
    result.gsub!(GITHUB_EMBED) do |_match|
      alt  = Regexp.last_match(1)
      path = Regexp.last_match(2)
      convert_embed_g2o(alt, path)
    end

    result.gsub!(GITHUB_LINK) do |_match|
      display = Regexp.last_match(1)
      target  = Regexp.last_match(2)
      convert_link_g2o(display, target)
    end

    result
  end

  def convert_link_g2o(display, target)
    # target can be: "page-name.md" or "page-name.md#heading"
    if target.include?('#')
      path, heading_slug = target.split('#', 2)
      heading = deslugify(heading_slug)
    else
      path    = target
      heading = nil
    end

    page = deslugify(path.sub(/\.md$/, ''))

    if heading
      default_display = "#{page}##{heading}"
      if display == default_display || display == page
        "[[#{page}##{heading}]]"
      else
        "[[#{page}##{heading}|#{display}]]"
      end
    else
      if display == page
        "[[#{page}]]"
      else
        "[[#{page}|#{display}]]"
      end
    end
  end

  def convert_embed_g2o(alt, path)
    filename = File.basename(path, File.extname(path))
    if alt == filename || alt.empty?
      "![[#{path}]]"
    else
      "![[#{path}|#{alt}]]"
    end
  end

  # --- Helpers --------------------------------------------------------------

  def slugify(text)
    text
      .strip
      .downcase
      .gsub(/[^\w\s\-\/.]/, '') # keep word chars, spaces, hyphens, slashes, dots
      .gsub(/\s+/, '-')
  end

  def deslugify(text)
    text
      .gsub('-', ' ')
      .gsub(/\b\w/, &:upcase) # title case each word
  end
end

return unless __FILE__ == $PROGRAM_NAME

# --- CLI --------------------------------------------------------------------

options = {
  direction:  nil,
  in_place:   false,
  backup:     false,
  output_dir: nil,
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} [options] <path>"

  opts.separator ""
  opts.separator "Direction (required, pick one):"

  opts.on("--o2g", "Convert Obsidian wikilinks → GitHub markdown links") do
    options[:direction] = :o2g
  end

  opts.on("--g2o", "Convert GitHub markdown links → Obsidian wikilinks") do
    options[:direction] = :g2o
  end

  opts.separator ""
  opts.separator "Output options (default: print to STDOUT):"

  opts.on("-i", "--in-place", "Modify files in place") do
    options[:in_place] = true
  end

  opts.on("-b", "--backup", "Create .bak files when using --in-place") do
    options[:backup] = true
  end

  opts.on("-o", "--output-dir DIR", "Write converted files to DIR") do |dir|
    options[:output_dir] = dir
  end

  opts.separator ""
  opts.on("-h", "--help", "Show this help") do
    puts opts
    exit
  end
end

parser.parse!

if options[:direction].nil?
  warn "Error: specify --o2g or --g2o"
  warn parser
  exit 1
end

if ARGV.empty?
  warn "Error: specify a file or directory path"
  warn parser
  exit 1
end

converter = O2G2O.new(**options.slice(:direction, :in_place, :backup, :output_dir))
ARGV.each { |path| converter.process_path(path) }
