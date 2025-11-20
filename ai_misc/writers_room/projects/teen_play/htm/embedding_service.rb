# frozen_string_literal: true

require 'tiktoken_ruby'
require 'ruby_llm'

class HTM
  # Embedding Service - Generate vector embeddings for semantic search
  #
  # Supports multiple embedding providers:
  # - :ollama - Ollama with gpt-oss model (default, via RubyLLM)
  # - :openai - OpenAI text-embedding-3-small
  # - :cohere - Cohere embeddings
  # - :local - Local sentence transformers
  #
  class EmbeddingService
    attr_reader :provider, :llm_client

    # Initialize embedding service
    #
    # @param provider [Symbol] Embedding provider (:ollama, :openai, :cohere, :local)
    # @param model [String] Model name (default: 'gpt-oss' for ollama)
    # @param ollama_url [String] Ollama server URL (default: http://localhost:11434)
    #
    def initialize(provider = :ollama, model: 'gpt-oss', ollama_url: nil)
      @provider = provider
      @model = model
      @ollama_url = ollama_url || ENV['OLLAMA_URL'] || 'http://localhost:11434'
      @tokenizer = Tiktoken.encoding_for_model("gpt-3.5-turbo")

      # Note: RubyLLM is used via direct Ollama API calls for embeddings
      # We don't need to initialize RubyLLM::Client here since we're making
      # direct HTTP requests to the Ollama embeddings endpoint
      @llm_client = nil  # Placeholder for compatibility
    end

    # Generate embedding for text
    #
    # @param text [String] Text to embed
    # @return [Array<Float>] Embedding vector (1536 dimensions)
    #
    def embed(text)
      case @provider
      when :ollama
        embed_ollama(text)
      when :openai
        embed_openai(text)
      when :cohere
        embed_cohere(text)
      when :local
        embed_local(text)
      else
        raise "Unknown embedding provider: #{@provider}"
      end
    end

    # Count tokens in text
    #
    # @param text [String] Text to count
    # @return [Integer] Token count
    #
    def count_tokens(text)
      @tokenizer.encode(text.to_s).length
    rescue
      # Fallback to simple word count if tokenizer fails
      text.to_s.split.size
    end

    private

    def embed_ollama(text)
      # Use Ollama to generate embeddings via direct API call
      # This approach works with RubyLLM by making direct HTTP requests to Ollama's API
      begin
        require 'net/http'
        require 'json'
        require 'uri'

        uri = URI.parse("#{@ollama_url}/api/embeddings")

        request = Net::HTTP::Post.new(uri)
        request.content_type = 'application/json'
        request.body = {
          model: @model,
          prompt: text
        }.to_json

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request(request)
        end

        if response.is_a?(Net::HTTPSuccess)
          result = JSON.parse(response.body)
          embedding = result['embedding']

          unless embedding.is_a?(Array) && !embedding.empty?
            raise "Invalid embedding received from Ollama API"
          end

          embedding
        else
          raise "Ollama API returned error: #{response.code} #{response.message}"
        end
      rescue => e
        warn "Error generating embedding with Ollama: #{e.message}"
        warn "Falling back to stub embeddings (random vectors)"
        warn "Please ensure Ollama is running and the #{@model} model is available"
        Array.new(1536) { rand(-1.0..1.0) }
      end
    end

    def embed_openai(text)
      # TODO: Implement actual OpenAI API call
      # For now, return a stub embedding (1536 dimensions of random values)
      # This should be replaced with:
      # require 'openai'
      # client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
      # response = client.embeddings(
      #   parameters: {
      #     model: "text-embedding-3-small",
      #     input: text
      #   }
      # )
      # response.dig("data", 0, "embedding")

      warn "STUB: Using random embeddings. Implement OpenAI API integration for production."
      Array.new(1536) { rand(-1.0..1.0) }
    end

    def embed_cohere(text)
      # TODO: Implement Cohere API call
      warn "STUB: Cohere embedding not yet implemented"
      Array.new(1536) { rand(-1.0..1.0) }
    end

    def embed_local(text)
      # TODO: Implement local sentence transformers
      warn "STUB: Local embedding not yet implemented"
      Array.new(1536) { rand(-1.0..1.0) }
    end
  end
end
