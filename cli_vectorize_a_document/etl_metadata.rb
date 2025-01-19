#!/usr/bin/env ruby
# scripts/etl_metadata.rb
#
# NOTE: This is _NOT_ a complete automated
#       solution.  The resulting CSV file
#       still need to be hand edited because
#       because of the inconsistent nature
#       of PART I
#


require 'amazing_print'
require 'pathname'
require 'csv'

repo_root     = Pathname.new(ENV.fetch('RR', '__dir__/..'))
docs_dir      = repo_root     + 'docs'
metadata_dir  = docs_dir      + 'test_document/edited'
input_file    = metadata_dir  + 'major.csv'
output_file   = metadata_dir  + 'structures.csv'

def filter_csv(input_file:, output_file:)
  previous_block_name = nil
  rows_to_write = []

  CSV.foreach(input_file, headers: true) do |row|
    current_block_name = row['block_name']

    if current_block_name != previous_block_name
      rows_to_write << row
      previous_block_name = current_block_name
    end
  end

  CSV.open(output_file, 'w', write_headers: true, headers: ['line_start', 'line_end', 'block_name']) do |csv|
    rows_to_write.each_with_index do |row, index|
      if row['line_end'] == '0' && index < rows_to_write.length - 1
        next_line_start = rows_to_write[index + 1]['line_start'].to_i
        row['line_end'] = (next_line_start - 1).to_s
      end
      csv << row
    end
  end
end

filter_csv(input_file: input_file, output_file: output_file)
