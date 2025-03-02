#! /usr/bin/env ruby
# experiments/ai_misc/embedder.rb
# See: https://gist.github.com/ahoward/2a1d45499ac9e755d802dbcbaf401b71


=begin

  1. clone https://huggingface.co/sentence-transformers/static-retrieval-mrl-en-v1

  2. gem install tokenizers onnxruntime

  3. generate embeddings on a __CPU__ at a rate of around 2000/s!


=end

require 'tokenizers'
require 'onnxruntime'
require 'securerandom'

tokenizer = Tokenizers.from_file("./static-retrieval-mrl-en-v1/0_StaticEmbedding/tokenizer.json")
model = OnnxRuntime::Model.new("./static-retrieval-mrl-en-v1/onnx/model.onnx")

a = Time.now.to_f
exp = (ARGV.shift || 14).to_i
n = 2 ** exp

n.times do

  tokens = tokenizer.encode("example text #{ SecureRandom.uuid_v7 }").ids

  attention_mask = Array.new([tokens.size, 1024].min, 1) + Array.new([1024 - tokens.size, 0].max, 0)

  embedding = model.predict({
    input_ids: [ tokens ],
    attention_mask: [ attention_mask ]
  })["sentence_embedding"].first

end

b = Time.now.to_f
e = b - a
rps = (n / e).round(2)


p(number: n, elapsed: e, rps:)

  #=> {:number=>16384, :elapsed=>7.348553895950317, :rps=>2229.55} !!!!!


__END__

  1. all the credit goes to https://github.com/khasinski - TY!!!!

  2. ref -> https://drawohara.io/nerd/fastest-possible-embeddings/
