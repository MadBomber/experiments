#!/usr/bin/env ruby
# scripts/create_chunk_files.rb

require 'debug_me'
include DebugMe

require 'amazing_print'
require_relative 'lib/database_connection'
require_relative 'lib/models'

repo_root     = Pathname.new(ENV.fetch('RR', '__dir__/..'))
docs_dir      = repo_root     + 'docs'
chunks_dir    = docs_dir      + 'test_document/chunks'

document          = Document.last
last_line_number  = document.contents.last.line_number

class TextFileGenerator
  WINDOW_SIZE = 50

  def initialize(out_dir:)
    @out_dir          = out_dir
    @document_id      = fetch_document_id
    @last_line_number = fetch_last_line_number
  end

  def add_references(lines)
    citations = []
    lines.each do |line_number|
      citation = get_citation(line_number)
      unless citations.include? citation
        citations << citation
      end
    end

    citations.map{|c| "Reference: #{c}"}
  end

  def add_header(contents_chunk, line_start, line_end)
    header  = []
    header  << "Document: #{Document.last.title}"
    header  << add_references(line_start..line_end)
    header  << ""

    contents_chunk.prepend header
  end

  def generate_text_files
    line_start = 1

    loop do
      contents_chunk = fetch_contents(line_start)
      break if contents_chunk.empty?

      line_end = line_start + WINDOW_SIZE - 1
      line_end = @last_line_number if line_end > @last_line_number

      contents_chunk = add_header(contents_chunk, line_start, line_end)

      # output_file_name = "#{@document_id}_#{line_start}_#{line_end}.txt"
      start_line  = sprintf("%06d", line_start)
      end_line    = sprintf("%06d", line_end)
      output_file_name = @out_dir + "#{@document_id}_#{start_line}_#{end_line}.txt"

      puts output_file_name.basename

      write_to_file(output_file_name, contents_chunk)

      break if line_end >= @last_line_number

      line_start += WINDOW_SIZE / 2
    end
  end

  private

  def get_citation(line_number)
    structures = Structure.where("lines @> ?::int", line_number)
                          .select("*, upper(lines) - lower(lines) AS range_size")
                          .order("range_size DESC")

    structures.map(&:block_name).join(" > ")
  end

  def fetch_document_id
    Document.last&.id || raise('No document found')
  end

  def fetch_last_line_number
    Document.last.contents.last.line_number
  end

  def fetch_contents(line_start)
    Content.where(document_id: @document_id)
           .where('line_number >= ?', line_start)
           .order(:line_number)
           .limit(WINDOW_SIZE)
           .pluck(:text)
  end

  def write_to_file(file_name, contents)
    File.open(file_name, 'w') do |file|
      contents.each { |line| file.puts(line) }
    end
  end
end

# Running the generator
if __FILE__ == $0
  generator = TextFileGenerator.new(out_dir: chunks_dir)
  generator.generate_text_files
end
