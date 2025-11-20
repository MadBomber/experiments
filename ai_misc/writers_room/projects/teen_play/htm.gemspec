# frozen_string_literal: true

require_relative "lib/htm/version"

Gem::Specification.new do |spec|
  spec.name = "htm"
  spec.version = HTM::VERSION
  spec.authors = ["Dewayne VanHoozer"]
  spec.email = ["dvanhoozer@gmail.com"]

  spec.summary = "Hierarchical Temporary Memory for LLM robots"
  spec.description = <<~DESC
    HTM (Hierarchical Temporary Memory) provides intelligent memory management for
    LLM-based applications (robots). It implements a two-tier memory system with
    durable long-term storage (PostgreSQL/TimescaleDB) and token-limited working
    memory, enabling robots to recall context from past conversations using RAG
    (Retrieval-Augmented Generation) techniques.
  DESC
  spec.homepage = "https://github.com/madbomber/htm"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "pg"
  spec.add_dependency "pgvector"
  spec.add_dependency "connection_pool"
  spec.add_dependency "tiktoken_ruby"
  spec.add_dependency "ruby_llm"

  # Development dependencies
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "debug_me"
end
