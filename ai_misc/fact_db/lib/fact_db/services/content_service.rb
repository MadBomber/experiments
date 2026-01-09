# frozen_string_literal: true

module FactDb
  module Services
    class ContentService
      attr_reader :config

      def initialize(config = FactDb.config)
        @config = config
      end

      def create(raw_text, type:, captured_at:, metadata: {}, title: nil, source_uri: nil)
        content_hash = Digest::SHA256.hexdigest(raw_text)

        # Check for duplicate content
        existing = Models::Content.find_by(content_hash: content_hash)
        return existing if existing

        embedding = generate_embedding(raw_text)

        Models::Content.create!(
          raw_text: raw_text,
          content_hash: content_hash,
          content_type: type.to_s,
          title: title,
          source_uri: source_uri,
          source_metadata: metadata,
          captured_at: captured_at,
          embedding: embedding
        )
      end

      def find(id)
        Models::Content.find(id)
      end

      def find_by_hash(hash)
        Models::Content.find_by(content_hash: hash)
      end

      def search(query, type: nil, from: nil, to: nil, limit: 20)
        scope = Models::Content.search_text(query)
        scope = scope.by_type(type) if type
        scope = scope.captured_after(from) if from
        scope = scope.captured_before(to) if to
        scope.order(captured_at: :desc).limit(limit)
      end

      def semantic_search(query, limit: 20)
        embedding = generate_embedding(query)
        return Models::Content.none unless embedding

        Models::Content.nearest_neighbors(embedding, limit: limit)
      end

      def by_type(type, limit: nil)
        scope = Models::Content.by_type(type).order(captured_at: :desc)
        scope = scope.limit(limit) if limit
        scope
      end

      def between(from, to)
        Models::Content.captured_between(from, to).order(captured_at: :asc)
      end

      def recent(limit: 10)
        Models::Content.order(captured_at: :desc).limit(limit)
      end

      def stats
        {
          total_count: Models::Content.count,
          by_type: Models::Content.group(:content_type).count,
          earliest: Models::Content.minimum(:captured_at),
          latest: Models::Content.maximum(:captured_at),
          total_words: Models::Content.sum("array_length(regexp_split_to_array(raw_text, '\\s+'), 1)")
        }
      end

      private

      def generate_embedding(text)
        return nil unless config.embedding_generator

        config.embedding_generator.call(text)
      rescue StandardError => e
        config.logger&.warn("Failed to generate embedding: #{e.message}")
        nil
      end
    end
  end
end
