#!/usr/bin/env ruby
# scripts/reformat_page_number_metadata.rb

require 'csv'
require 'fileutils'

def reformat_cross_reference(input_file:, output_file:)
  entries = File.readlines(input_file).map do |line|
    line_number, page_number = line.chomp.split(':').map(&:strip)
    [line_number.to_i, page_number]
  end

  formatted_entries = []
  previous_line_end = 1  # The first entry's line_start is set to 1

  entries.each_with_index do |(line_end, page_number), _index|
    line_start = previous_line_end
    formatted_entries << [line_start, line_end, page_number]  # Store as an array for CSV

    previous_line_end = line_end + 1  # For the next entry
  end

  CSV.open(output_file, 'w') do |csv|
    formatted_entries.each { |entry| csv << entry }  # Writes as a CSV row
  end
end

# Main execution
input_file = ARGV[0]

# Check for command-line arguments
if input_file.nil? || !File.exist?(input_file) || File.extname(input_file) != '.txt'
  puts "Usage: #{$0} input_file.txt"
  exit 1
end

# Determine output file path based on input file
output_file = File.join(File.dirname(input_file), "#{File.basename(input_file, '.txt')}.csv")

# Run the reformat cross-references and handle potential errors
begin
  reformat_cross_reference(input_file: input_file, output_file: output_file)
  puts "Output written to #{output_file}"
rescue => e
  puts "An error occurred: #{e.message}"
end
