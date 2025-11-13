# frozen_string_literal: true

require_relative "lib/simple_flow/version"

Gem::Specification.new do |spec|
  spec.name = "simple_flow"
  spec.version = SimpleFlow::VERSION
  spec.authors = ["MadBomber"]
  spec.email = [""]

  spec.summary = "A lightweight, modular Ruby framework for building composable data processing pipelines"
  spec.description = "SimpleFlow provides a clean and flexible architecture for orchestrating multi-step workflows with middleware support, flow control, and async fiber-based DAG execution for high-concurrency I/O operations"
  spec.homepage = "https://github.com/madbomber/experiments"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/madbomber/experiments"
  spec.metadata["changelog_uri"] = "https://github.com/madbomber/experiments/blob/main/simple_flow/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[
    lib/**/*.rb
    docs/**/*.svg
    README.md
    LICENSE
    CHANGELOG.md
  ]).reject { |f| File.directory?(f) }

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "async", "~> 2.0"

  # Development dependencies
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "async-http", "~> 0.60"
end
