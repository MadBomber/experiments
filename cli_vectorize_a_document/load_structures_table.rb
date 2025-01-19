#!/usr/bin/env ruby
# scripts/load_structures_table.rb

require 'csv'
require_relative 'lib/database_connection'
require_relative 'lib/models'

repo_root     = Pathname.new(ENV.fetch('RR', '__dir__/..'))
docs_dir      = repo_root     + 'docs'
metadata_dir  = docs_dir      + 'test_document/edited'
csv_file_path = metadata_dir  + 'structures.csv'

document_id   = Document.last.id  # there is only 1 document


def truncate_structures_table
  Structure.connection.execute('TRUNCATE TABLE structures RESTART IDENTITY')
  puts "Structures table truncated."
end


def load_structures_from_csv(file_path:, document_id:)
  CSV.foreach(file_path, headers: true) do |row|
    begin
      # Create an INT4RANGE object
      lines_range = "[#{row['line_start']},#{row['line_end']})"

      structure = Structure.new(
        document_id: document_id,
        block_name: row['block_name'],
        lines: lines_range  # Use the INT4RANGE here
      )

      unless structure.save
        puts "Failed to save structure: #{structure.errors.full_messages.join(", ")}"
      else
        puts "Successfully saved structure: #{structure.inspect}"
      end
    rescue StandardError => e
      puts "Error processing row: #{row}. Error: #{e.message}"
    end
  end
end



def sanity_check
  min_line = Structure.minimum('lower(lines)')
  max_line = Structure.maximum('upper(lines)')

  puts "Sanity Check Results:"
  puts "Smallest line number: #{min_line}"
  puts "Largest line number: #{max_line}"
end

def find_structures_for_line(line_number)
  structures = Structure.where("lines @> ?::int", line_number)
                        .select("*, upper(lines) - lower(lines) AS range_size")
                        .order("range_size DESC")

  puts "Structures containing line #{line_number}:"
  structures.each do |structure|
    puts "ID: #{structure.id}, Block Name: #{structure.block_name}, Lines: #{structure.lines}, Size: #{structure.range_size}"
  end

  citation = "Citation: " + structures.map(&:block_name).join(" > ")
  puts citation

  structures
end



# clean out the existing data
truncate_structures_table


load_structures_from_csv(file_path: csv_file_path, document_id: document_id)


sanity_check

# TODO: get the last line number from the database rather that hardcoded
random_line_numbers = Array.new(25) { rand(25975)+1 }

random_line_numbers.each do |line_number|
  puts "="*10
  find_structures_for_line line_number
end
