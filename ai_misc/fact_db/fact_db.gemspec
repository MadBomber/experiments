# frozen_string_literal: true

require_relative "lib/fact_db/version"

Gem::Specification.new do |spec|
  spec.name = "fact_db"
  spec.version = FactDb::VERSION
  spec.authors = ["Dewayne VanHoozer"]
  spec.email = ["dvanhoozer@gmail.com"]

  spec.summary = "Temporal fact tracking with entity resolution and audit trails"
  spec.description = <<~DESC
    FactDb implements the Event Clock concept - capturing organizational reasoning
    through temporal facts with validity periods (valid_at/invalid_at), entity resolution,
    and audit trails back to source content. Built on PostgreSQL with pgvector support
    for semantic search.
  DESC
  spec.homepage = "https://github.com/MadBomber/fact_db"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Core dependencies
  spec.add_dependency "activerecord", ">= 7.0"
  spec.add_dependency "pg", ">= 1.5"
  spec.add_dependency "neighbor", ">= 0.3"

  # Configuration
  spec.add_dependency "anyway_config", ">= 2.0"

  # Date/Time parsing
  spec.add_dependency "chronic", ">= 0.10"

  # Pipeline orchestration
  spec.add_dependency "simple_flow", ">= 0.2"

  # LLM Integration (optional - add to your Gemfile if using LLM extraction)
  # spec.add_dependency "ruby_llm", ">= 1.0"

  # Development dependencies
  spec.add_development_dependency "minitest", ">= 5.0"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "debug_me"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "yard"
end
