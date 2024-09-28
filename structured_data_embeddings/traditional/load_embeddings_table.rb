#!/usr/bin/env ruby
# scripts/load_embeddings_table.rb
#
# NOTE: This program is hard coded to process
#       chunked files for the VA HR Handbook
#       which means those chunked files must
#       exust before this program is executed.
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

require_relative 'lib/database_connection'
require_relative 'lib/my_client'

# llama3.1
model   = ENV.fetch('EMBED_MODEL', 'nomic-embed-text')

# This is _ONLY_ required if the emvedding host is a non-local
# instance of Ollama.
host    = ENV.fetch('OLLAMA_HOST', nil)
api_key = ENV.fetch('OLLAMA_API_KEY', nil)

# if host
#   debug_me('Going outside localhost'){[
#     :host,
#     :model,
#     :api_key
#   ]}
#   # Ensure the host is a valid URL
#   host = "https://#{host}" unless host.start_with?('http://', 'https://')
#   Client  = OmniAI::OpenAI::Client.new(
#               host:     host,
#               api_key:  api_key,
#             )
# else
  Client  = MyClient.new(model)
# end

repo_root     = Pathname.new(ENV.fetch('RR', '__dir__/..'))
data_dir      = repo_root     + 'data'



def vectorize(contents)
  embeddings = Client.embed(contents)

  embeddings.data['data'].first['embedding']
end

chunks = data_dir.children.select{|c| '.txt' == c.extname}


progressbar = ProgressBar.create(
  title:  'Chunks',
  total:  chunks.size,
  format: '%t: [%B] %c/%C %j%% %e',
  output: STDERR
)


chunks.each do |chunk|
  progressbar.increment
  data      = Pathname.new(chunk.to_s.gsub('.txt', '.json')).read
  content   = chunk.read
  values    = ARGV.include?('--json') ? vectorize(data) : vectorize(content)


  Embedding.create(
    data:     data,
    content:  content,
    values:   values
  )
end

progressbar.finish
