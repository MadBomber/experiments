#!/usr/bin/env ruby
# experiments/ai_misc/using_onnx_models.rb
#
# gem install tokenizers onnxruntime
# git clone https://huggingface.co/sentence-transformers/static-retrieval-mrl-en-v1

require 'tokenizers'
require 'onnxruntime'

tokenizer = Tokenizers.from_file("./static-retrieval-mrl-en-v1/0_StaticEmbedding/tokenizer.json")
model = OnnxRuntime::Model.new("./static-retrieval-mrl-en-v1/onnx/model.onnx")

text = "Finish the follow kids story:  Once upon a time there were 3 little pigs ..."

tokens = tokenizer.encode(text).ids

attention_mask = Array.new([tokens.size, 1024].min, 1) + Array.new([1024 - tokens.size, 0].max, 0)

puts model.predict({
  input_ids: [ tokens ],
  attention_mask: [ attention_mask ]
})["sentence_embedding"].first
