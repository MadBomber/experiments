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

# brew install gron
json_normalizer_pgm = 'gron'

require 'ai_client'

require 'ruby-progressbar'
require 'optparse'

require_relative 'lib/database_connection'


# Parse command line options
options = {from: 'text'}
OptionParser.new do |opts|
  opts.on('--from TYPE', ['text', 'json'], "Source type (text or json)") do |v|
    options[:from] = v
  end
end.parse!

# llama3.1
model   = ENV.fetch('EMBED_MODEL', 'nomic-embed-text')

# This is _ONLY_ required if the emvedding host is a non-local
# instance of Ollama.
host    = ENV.fetch('OLLAMA_HOST', nil)
api_key = ENV.fetch('OLLAMA_API_KEY', nil)


Client  = AiClient.new(model)

repo_root     = Pathname.new(ENV.fetch('RR', '__dir__/..'))
data_dir      = repo_root     + 'data'



def vectorize(contents)
  embeddings = Client.embed(contents)

  embeddings.data['data'].first['embedding']
end

chunks = data_dir.children.select{|c| '.json' == c.extname}

progressbar = ProgressBar.create(
  title:  'Chunks',
  total:  chunks.size,
  format: '%t: [%B] %c/%C %j%% %e',
  output: STDERR
)


chunks.each do |chunk|
  progressbar.increment
  raw_json  = chunk.read            # raw json is just a string
  data      = JSON.parse(raw_json)  # turn into Hash; let AR manage serialization
  content   = `#{json_normalizer_pgm} #{chunk}`
  values    = 'json' == options[:from] ? vectorize(raw_json) : vectorize(content)

  Embedding.create(
    data:     data,
    content:  content,
    values:   values
  )
end

progressbar.finish
