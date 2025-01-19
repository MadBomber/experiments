#!/usr/bin/env ruby
# scripts/load_embeddings_table.rb
#
# NOTE: This program is hard coded to process
#       chunked files for the Test Document
#       which means those chunked files must
#       exist before this program is executed.
#
# As currently configured this program uses a small
# embedding model 'nomic-embed-text' with Ollama running
# on the localhost.  There is an envar available for
# accessing Ollama on a remote host but that has not been
# tested.  But I suppose that we can make the model
# available from an envar that goes to a remote host like
# OpenAI or its competitors.... that makes sense to me.
#
# Environment Variables
#   EMBED_MODEL .... The name of the model to use for embeddings
#   OLLAMA_HOST .... The host for the provided (only needed for Ollama)
#
# CAUTION:  The embedding model controllers the dimension
#           of the vector.  CUrrently it is hardcoded in
#           both the SQL that creates the embeddings table
#           as well as here for 768 which is what
#           nomic-embed-text model provides.  If that
#           model is not used, then the hard coded dimension
#           must change.
#

require 'ruby-progressbar'
require 'ai_client'

require_relative 'lib/database_connection'

# llama3.1
model   = ENV.fetch('EMBED_MODEL', 'llama3.1')

# This is _ONLY_ required if the emvedding host is a non-local
# instance of Ollama.
# host    = ENV.fetch('OLLAMA_HOST', nil)
# api_key = ENV.fetch('OLLAMA_API_KEY', nil)

Client  = AiClient.new(model)


repo_root     = Pathname.new(ENV.fetch('RR', '__dir__/..'))
docs_dir      = repo_root     + 'docs'
chunks_dir    = docs_dir      + 'test_document/chunks'

document_id   = Document.last.id  # there is only 1 document

chunks    = chunks_dir.children.select{|c| '.txt' == c.extname.to_s}
how_many  = chunks.size

# Extract the document_id, line_start and line_end
# from the file name.
def extract_params(a_string)
  # pattern is "test_document.txt"
  parts = a_string.split('_')
  document_id = parts[1].to_i
  line_start  = parts[2].to_i
  line_end    = parts[3].to_i

  [document_id, (line_start..line_end)]
end

def vectorize(contents)
  embeddings = Client.embed(contents)

  embeddings.data['data'].first['embedding']
end

progressbar = ProgressBar.create(
  title:  'Chunks',
  total:  how_many,
  format: '%t: [%B] %c/%C %j%% %e',
  output: STDERR
)


chunks.each do |chunk|
  progressbar.increment

  document_id, lines = extract_params chunk.basename.to_s
  contents  = chunk.read
  values    = vectorize(contents)
  # debug_me{[
  #   'values.class',
  #   'values.to_a',
  #   'values.to_a.size',
  #   'values.methods.sort',
  # ]}

  Embedding.create(
    document_id:  document_id,
    lines:        lines,
    values:       values
  )
end

progressbar.finish
