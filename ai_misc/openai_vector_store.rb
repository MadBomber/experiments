#!/usr/bin/env ruby
# ai_misc/openai_vector_store.rb

require 'openai'

# Initialize the OpenAI client.
client = OpenAI::Client.new(
  access_token: ENV['OPENAI_API_KEY'],
  log_errors: true  # Enable error logging during development to see detailed API errors.
)

# Retrieve all markdown files from the "md" directory.
# In this example I'm using Markdown, but you can upload any of these:
# https://platform.openai.com/docs/assistants/tools/file-search#supported-files
markdown_files = Dir['md/*.md']

# Total number of markdown files.
total_files = markdown_files.length

# Array to store the IDs of files once they have been uploaded.
uploaded_file_ids = []

# Iterate over each markdown file, uploading it and logging its details.
markdown_files.each_with_index do |file_path, index|
  puts "Uploading file #{index + 1} of #{total_files}: #{file_path}"

  # Upload the file to OpenAI for the specified purpose.
  upload_response = client.files.upload(parameters: { file: file_path, purpose: 'assistants' })
  uploaded_file_id = upload_response['id']

  # Save the uploaded file ID in our array for later use.
  uploaded_file_ids << uploaded_file_id

  # Log the uploaded file ID to a file for reference.
  File.open('file_ids.txt', 'a') do |log_file|
    log_file.puts(uploaded_file_id)
  end

  # Also log the file ID along with its file path for additional context.
  File.open('file_ids_with_name.txt', 'a') do |log_file|
    log_file.puts("#{uploaded_file_id}, #{file_path}")
  end
end

# Create a new vector store on OpenAI.
vector_store_response = client.vector_stores.create(
  parameters: {
    name: 'my_vector_store',
    file_ids: []  # Initially empty; we'll add file IDs in batches.
  }
)

# Extract the vector store ID from the response.
vector_store_id = vector_store_response['id']

# Add the uploaded file IDs to the vector store in batches of 100.
uploaded_file_ids.each_slice(100) do |file_ids_batch|
  batch_response = client.vector_store_file_batches.create(
    vector_store_id: vector_store_id,
    parameters: {
      file_ids: file_ids_batch
    }
  )

  batch_id = batch_response['id']
  puts "Created batch with ID: #{batch_id}"
end
