---
name: rubyllm/red_candle
version: 0.2.0
description: |
  Local LLM execution with quantized GGUF models for RubyLLM. Use this skill when running models locally for zero latency, no API costs, complete privacy, and offline capability. Supports Metal (macOS), CUDA (NVIDIA), and CPU.
---

# RubyLLM::RedCandle v{{ page.version }}

**Local LLM Execution with Quantized Models**

Run LLMs locally using quantized GGUF models through the Red Candle gem. Zero latency, no API costs, complete privacy, offline capable.

**Gem Version:** 0.2.0
**GitHub:** https://github.com/scientist-labs/ruby_llm-red_candle

**Note:** Requires Rust toolchain for native extensions.

## Installation

```bash
gem 'ruby_llm-red_candle'
```

### Rust Toolchain

```bash
curl --proto '=https' --sh https://sh.rustup.rs -sSf | sh
rustc --version
```

## Configuration

```ruby
# config/initializers/ruby_llm.rb
RubyLLM.configure do |config|
  config.red_candle_model_path = '/path/to/model.gguf'
  config.red_candle_n_threads = 8
  config.red_candle_n_gpu_layers = 0  # Set > 0 for GPU acceleration
end
```

## Basic Usage

```ruby
require 'ruby_llm/red_candle'

chat = RubyLLM.chat(model: 'local', provider: 'red_candle')
response = chat.ask "Hello!"
puts response.content

# Streaming
chat.ask "Write a story" do |chunk|
  print chunk.content
end
```

## Supported Models

Models are automatically downloaded from HuggingFace on first use.

### TinyLlama

```ruby
RubyLLM.configure do |config|
  config.red_candle_model_path = 'TinyLlama/TinyLlama-1.1B-Chat-v1.0'
end
```

### Qwen2.5

```ruby
RubyLLM.configure do |config|
  config.red_candle_model_path = 'Qwen/Qwen2.5-3B-Instruct-GGUF'
end
```

### Gemma-3

```ruby
RubyLLM.configure do |config|
  config.red_candle_model_path = 'google/gemma-3-4b-it-GGUF'
end
```

### Phi-3

```ruby
RubyLLM.configure do |config|
  config.red_candle_model_path = 'microsoft/Phi-3-mini-4k-instruct-GGUF'
end
```

### Mistral-7B

```ruby
RubyLLM.configure do |config|
  config.red_candle_model_path = 'mistralai/Mistral-7B-Instruct-v0.3-GGUF'
end
```

### Llama-3

```ruby
RubyLLM.configure do |config|
  config.red_candle_model_path = 'meta-llama/Meta-Llama-3-8B-Instruct-GGUF'
end
```

## Hardware Acceleration

### Metal (macOS) — M-series chips

```ruby
RubyLLM.configure do |config|
  config.red_candle_use_metal = true
  config.red_candle_n_gpu_layers = 35  # Offload layers to GPU
end
```

### CUDA (NVIDIA)

```ruby
RubyLLM.configure do |config|
  config.red_candle_use_cuda = true
  config.red_candle_n_gpu_layers = 35
end
```

### CPU (Default)

```ruby
RubyLLM.configure do |config|
  config.red_candle_n_threads = 8
end
```

## Model Download

Models are automatically downloaded from HuggingFace and cached in `~/.cache/red_candle/`.

### Manual Download

```ruby
RubyLLM::RedCandle.download_model(
  repo: 'TinyLlama/TinyLlama-1.1B-Chat-v1.0',
  file: 'model.gguf'
)
```

## Performance Tuning

```ruby
RubyLLM.configure do |config|
  config.red_candle_n_ctx = 2048    # Context window size
  config.red_candle_n_batch = 512   # Prompt batch size
  config.red_candle_use_mmap = true # Memory-map model file
end
```

## Use Cases

### Development & Testing Without API Costs

```ruby
if Rails.env.development?
  RubyLLM.configure do |config|
    config.red_candle_model_path = 'TinyLlama/TinyLlama-1.1B-Chat-v1.0'
    config.red_candle_use_metal = true
    config.red_candle_n_gpu_layers = 35
  end
else
  RubyLLM.configure do |config|
    config.anthropic_api_key = ENV['ANTHROPIC_API_KEY']
  end
end
```

### Privacy-Sensitive Applications

```ruby
class MedicalAssistant < RubyLLM::Agent
  model 'local', provider: 'red_candle'
  instructions "Handle patient data confidentially."
end
```

### Offline Applications

```ruby
chat = RubyLLM.chat(model: 'local', provider: 'red_candle')
chat.ask "Help me write"  # No API calls
```

## Limitations

- Local models may be less capable than cloud models
- Slower than cloud APIs without GPU acceleration
- Large models require significant RAM (1GB–10GB+)

## Troubleshooting

### Rust Compilation Errors

```bash
rustup update
gem uninstall ruby_llm-red_candle
gem install ruby_llm-red_candle --no-cache
```

### Out of Memory

```ruby
RubyLLM.configure do |config|
  config.red_candle_n_ctx = 1024
  config.red_candle_use_mmap = true
end
```

### Slow Performance

```ruby
RubyLLM.configure do |config|
  config.red_candle_n_gpu_layers = 35
  config.red_candle_n_threads = 4
end
```

## See Also

- **Main RubyLLM**: [rubyllm](../rubyllm/SKILL.md)
- **Red Candle**: https://github.com/scientist-labs/red-candle
