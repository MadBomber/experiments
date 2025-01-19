#!/usr/bin/env bash
# Create the database and its tables
# The load the tables with content.

psql -f sql/create_database.sql -f sql/create_tables.sql

# pdf2txt $document
# extract_block_references.sh $document

echo "Manual step to create TEXT version of document"

# Install all the Ruby gems used
bundle install

# add content to the documents and contents tables
# for every *.txt file in the docs directory
# should be only one in this experimental project.
load_documents_table.rb

echo "Manual: create some metadata files"

# Extract manipulate some of the metadata
# created the structures.csv file
# lets use what has already been implemented
# in this branch.
# etl_metadata.rb

# add the content from the structures.csv
# file into the structures table
load_structures_table.rb

# Create the chunk files for the last documented
# loaded into the database.
create_chunk_files.rb

# Process each of the chunk files into the
# embeddings table using an embedding LLM to
# vectorize the content of the chunk file.
# We are currently hardcoded to chunk at 50
# lines with a 50% overlap.
load_embeddings_table.rb

