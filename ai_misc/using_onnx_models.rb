#!/usr/bin/env ruby
# experiments/ai_misc/using_onnx_models.rb

require 'tokenizers'
require 'onnxruntime'

tokenizer = Tokenizers.from_file("./static-retrieval-mrl-en-v1/0_StaticEmbedding/tokenizer.json")
model = OnnxRuntime::Model.new("./static-retrieval-mrl-en-v1/onnx/model.onnx")

tokens = tokenizer.encode("example text").ids

attention_mask = Array.new([tokens.size, 1024].min, 1) + Array.new([1024 - tokens.size, 0].max, 0)

puts model.predict({
  input_ids: [ tokens ],
  attention_mask: [ attention_mask ]
})["sentence_embedding"].first


