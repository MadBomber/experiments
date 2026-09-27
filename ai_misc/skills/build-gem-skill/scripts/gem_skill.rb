#!/usr/bin/env ruby
# frozen_string_literal: true

# gem_skill.rb — the deterministic half of the build-gem-skill Claude skill.
#
# Mirrors the non-LLM parts of the gem-skill gem (Lockfile, Fetcher,
# Frontmatter, Cache, Linker) so a skill written by Claude lands in exactly
# the same place, with the same frontmatter and metadata.json, as one built by
# `gem skill install`. Claude performs the generate/verify steps itself.
#
# Standard library only. Every command prints JSON to STDOUT.
#
#   ruby gem_skill.rb resolve GEM [VERSION]
#   ruby gem_skill.rb sources GEM VERSION [--out FILE]
#   ruby gem_skill.rb source-code GEM VERSION [--out FILE]
#   ruby gem_skill.rb store GEM VERSION DRAFT_FILE --model MODEL [--sources a,b]
#   ruby gem_skill.rb apply-verify GEM VERSION (CORRECTED_FILE | --unverifiable) --model MODEL
#   ruby gem_skill.rb link GEM VERSION [--project DIR]
#   ruby gem_skill.rb lockfile [PATH]
#   ruby gem_skill.rb status [--lockfile PATH] [--project DIR]
#   ruby gem_skill.rb prune [--project DIR]
#   ruby gem_skill.rb list
#   ruby gem_skill.rb purge GEM (VERSION | --all)

require "fileutils"
require "json"
require "net/http"
require "rubygems"
require "time"
require "tmpdir"
require "uri"

module GemSkill
  class Error < StandardError; end

  DEFAULT_CACHE_ROOT  = "~/.gem/skills"
  DEFAULT_PROJECT_DIR = ".claude/skills"

  RUBYGEMS_API  = "https://rubygems.org/api/v1/gems/%s.json"
  GITHUB_RAW    = "https://raw.githubusercontent.com/%s/%s/%s"
  MAX_REDIRECTS = 5
  OPEN_TIMEOUT  = 5
  READ_TIMEOUT  = 10

  README_CANDIDATES    = %w[README.md README.rdoc README.txt README].freeze
  CHANGELOG_CANDIDATES = %w[CHANGELOG.md CHANGELOG.rdoc HISTORY.md CHANGES.md].freeze

  MAX_SOURCE_CHARS       = 60_000   # per doc source, same as Generator::MAX_SOURCE_CHARS
  SOURCE_CODE_MAX_CHARS  = 150_000  # lib/**/*.rb bundle for verification
  MAX_NAME_LENGTH        = 40
  MAX_DESCRIPTION_LENGTH = 500

  module_function

  # --- paths -------------------------------------------------------------

  def cache_root(env = ENV)
    File.expand_path(env.fetch("GEMSKILL_DIR", DEFAULT_CACHE_ROOT))
  end

  def skill_dir(gem_name, version, root = cache_root)
    File.join(root, gem_name, version)
  end

  def skill_path(gem_name, version, root = cache_root)
    File.join(skill_dir(gem_name, version, root), "SKILL.md")
  end

  def metadata_path(gem_name, version, root = cache_root)
    File.join(skill_dir(gem_name, version, root), "metadata.json")
  end

  def project_dir(env = ENV)
    value = env.fetch("GEMSKILL_PROJECT_DIR", DEFAULT_PROJECT_DIR).to_s.strip
    value.empty? ? DEFAULT_PROJECT_DIR : value
  end

  def project_skills_dir(project_root = Dir.pwd, env = ENV)
    File.join(project_root, project_dir(env))
  end

  def scratch_path(gem_name, version, kind)
    dir = File.join(Dir.tmpdir, "build-gem-skill")
    FileUtils.mkdir_p(dir)
    File.join(dir, "#{gem_name}-#{version}-#{kind}.md")
  end

  # --- gem resolution ----------------------------------------------------

  def find_spec(gem_name, version = nil)
    version ? Gem::Specification.find_by_name(gem_name, version) : Gem::Specification.find_by_name(gem_name)
  rescue Gem::MissingSpecError, Gem::MissingSpecVersionError
    nil
  end

  def gem_dir(gem_name, version, spec = find_spec(gem_name, version))
    return spec.gem_dir if spec && File.directory?(spec.gem_dir)

    Gem.path.each do |base|
      path = File.join(base, "gems", "#{gem_name}-#{version}")
      return path if File.directory?(path)
    end
    nil
  end

  def resolve(gem_name, version = nil)
    spec = find_spec(gem_name, version)
    resolved = spec&.version&.to_s || version
    {
      gem:       gem_name,
      version:   resolved,
      installed: !spec.nil?,
      gem_dir:   resolved && gem_dir(gem_name, resolved, spec),
      cached:    !resolved.nil? && File.exist?(skill_path(gem_name, resolved))
    }
  end

  # --- doc sources (Fetcher) ---------------------------------------------

  def read_first(dir, candidates)
    return nil unless dir

    candidates.each do |name|
      path = File.join(dir, name)
      return File.read(path, encoding: "utf-8").scrub if File.file?(path)
    end
    nil
  end

  def spec_metadata(spec)
    lines = ["**Gem:** #{spec.name} #{spec.version}"]
    lines << "**Summary:** #{spec.summary}"                              unless spec.summary.to_s.strip.empty?
    lines << "**Description:** #{spec.description}"                     unless spec.description.to_s.strip.empty?
    lines << "**Author(s):** #{spec.authors.join(', ')}"                if spec.authors.any?
    lines << "**Homepage:** #{spec.homepage}"                           unless spec.homepage.to_s.strip.empty?
    lines << "**License(s):** #{spec.licenses.join(', ')}"              if spec.licenses.any?
    lines << "**Source:** #{spec.metadata['source_code_uri']}"          if spec.metadata["source_code_uri"]
    lines << "**Documentation:** #{spec.metadata['documentation_uri']}" if spec.metadata["documentation_uri"]

    deps = spec.runtime_dependencies
    lines << "**Runtime dependencies:** #{deps.map { "#{it.name} (#{it.requirement})" }.join(', ')}" if deps.any?
    lines.join("\n")
  end

  def rubygems_metadata(data)
    return nil unless data

    lines = ["**Gem:** #{data['name']} #{data['version']}"]
    lines << "**Summary:** #{data['info']}"                    unless data["info"].to_s.strip.empty?
    lines << "**Homepage:** #{data['homepage_uri']}"           if data["homepage_uri"]
    lines << "**Source:** #{data['source_code_uri']}"          if data["source_code_uri"]
    lines << "**Documentation:** #{data['documentation_uri']}" if data["documentation_uri"]

    deps = data.dig("dependencies", "runtime") || []
    lines << "**Runtime dependencies:** #{deps.map { "#{it['name']} (#{it['requirements']})" }.join(', ')}" if deps.any?
    lines.join("\n")
  end

  def examples(dir)
    return nil unless dir

    examples_dir = File.join(dir, "examples")
    files = Dir.glob(File.join(examples_dir, "**", "*.{rb,md}")).sort
    return nil if files.empty?

    files.map do |path|
      "### #{path.delete_prefix("#{examples_dir}/")}\n\n```\n#{File.read(path, encoding: 'utf-8').scrub.strip}\n```"
    end.join("\n\n")
  end

  def github_repo(data)
    return nil unless data

    [data["source_code_uri"], data["homepage_uri"]].compact.each do |uri|
      match = uri.match(%r{github\.com[/:](?<owner>[^/]+)/(?<repo>[^/.\s]+?)(?:\.git)?(?:/|$)})
      return "#{match[:owner]}/#{match[:repo]}" if match
    end
    nil
  end

  def github_readme(repo, fetcher: method(:fetch_url))
    return nil unless repo

    README_CANDIDATES.each do |filename|
      %w[main master].each do |branch|
        content = fetcher.call(format(GITHUB_RAW, repo, branch, filename))
        return content if content
      end
    end
    nil
  end

  def rubygems_data(gem_name, fetcher: method(:fetch_url))
    body = fetcher.call(format(RUBYGEMS_API, gem_name))
    body ? JSON.parse(body) : nil
  rescue JSON::ParserError
    nil
  end

  # Same priority order as Gem::Skill::Fetcher: local install first, then the
  # RubyGems API for metadata and GitHub for the README.
  def fetch_sources(gem_name, version)
    spec   = find_spec(gem_name, version)
    dir    = gem_dir(gem_name, version, spec)
    readme = read_first(dir, README_CANDIDATES)
    remote = rubygems_data(gem_name) if spec.nil? || readme.nil?

    {
      metadata:  spec ? spec_metadata(spec) : rubygems_metadata(remote),
      readme:    readme || github_readme(github_repo(remote)),
      changelog: read_first(dir, CHANGELOG_CANDIDATES),
      examples:  examples(dir)
    }.compact
  end

  def format_sources(sources, max_chars = MAX_SOURCE_CHARS)
    sources.map do |name, content|
      body = content.length > max_chars ? "#{content[0, max_chars]}\n[... truncated ...]" : content
      "### #{name.to_s.upcase}\n\n#{body}"
    end.join("\n\n---\n\n")
  end

  # lib/**/*.rb concatenated with per-file headers, whole files only, capped.
  def source_bundle(dir, max_chars = SOURCE_CODE_MAX_CHARS)
    return nil unless dir

    files = Dir.glob(File.join(dir, "lib", "**", "*.rb")).sort
    out, included, truncated = +"", [], false

    files.each do |path|
      relative = path.delete_prefix("#{dir}/")
      chunk = "### #{relative}\n\n```ruby\n#{File.read(path, encoding: 'utf-8').scrub}\n```\n\n"
      if !out.empty? && out.length + chunk.length > max_chars
        truncated = true
        break
      end
      out << chunk
      included << relative
    end

    out.empty? ? nil : { code: out, files: included, chars: out.length, truncated: truncated }
  end

  def fetch_url(url, redirects_left = MAX_REDIRECTS)
    return nil if redirects_left.zero?

    uri = URI(url)
    uri.scheme = "https" if uri.scheme == "http"
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                               open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
      http.get(uri.request_uri, "User-Agent" => "build-gem-skill")
    end

    case response
    when Net::HTTPSuccess     then response.body.force_encoding("utf-8").scrub
    when Net::HTTPRedirection then fetch_url(response["location"], redirects_left - 1)
    end
  rescue StandardError
    nil
  end

  # --- content post-processing (Generator + Frontmatter) -----------------

  # Remove a ```markdown fence wrapping the ENTIRE document; a trailing code
  # block's closing fence is kept unless an opening wrapper fence was present.
  def strip_wrapper_fence(content)
    stripped = content.strip
    return stripped unless stripped.match?(/\A```(?:markdown)?\s*\n/)

    stripped.sub(/\A```(?:markdown)?\s*\n/, "").sub(/\n```\s*\z/, "").strip
  end

  def strip_frontmatter(content)
    content.to_s.sub(/\A\s*---\s*\n.*?\n---\s*\n+/m, "").lstrip
  end

  def slug(gem_name)
    s = gem_name.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
    s = "skill" if s.empty?
    s[0, MAX_NAME_LENGTH].sub(/-+\z/, "")
  end

  def description_for(gem_name, version, body)
    overview = body[/^##\s+Overview\s*\n+(.+?)(?=\n\s*\n|\n##\s|\z)/m, 1]
    text = overview || "Ruby gem #{gem_name}. Use when working with #{gem_name} in Ruby code."
    text = text.gsub(/\s+/, " ").delete("<>").strip
    text = "#{text} (#{gem_name} v#{version})" unless text.include?(version.to_s)
    text[0, MAX_DESCRIPTION_LENGTH].strip
  end

  def yaml_quote(str)
    %("#{str.gsub(/[\\"]/) { "\\#{it}" }}")
  end

  def build_frontmatter(gem_name, version, content)
    body = strip_frontmatter(content)
    "---\nname: #{slug(gem_name)}\ndescription: #{yaml_quote(description_for(gem_name, version, body))}\n---\n\n#{body}"
  end

  def normalize(text)
    text.to_s.gsub(/[ \t]+$/, "").strip
  end

  # --- cache -------------------------------------------------------------

  def read_metadata(gem_name, version, root = cache_root)
    path = metadata_path(gem_name, version, root)
    File.exist?(path) ? JSON.parse(File.read(path)) : {}
  rescue JSON::ParserError
    {}
  end

  def store(gem_name, version, draft, model:, sources:, root: cache_root, now: Time.now)
    content = build_frontmatter(gem_name, version, strip_wrapper_fence(draft))
    FileUtils.mkdir_p(skill_dir(gem_name, version, root))
    File.write(skill_path(gem_name, version, root), content)
    File.write(metadata_path(gem_name, version, root), JSON.generate(
      "sources" => sources, "model" => model, "gem_name" => gem_name,
      "version" => version, "generated_at" => now.iso8601
    ))
    { stored: skill_path(gem_name, version, root), name: slug(gem_name), chars: content.length }
  end

  def merge_metadata(gem_name, version, extra, root = cache_root)
    data = read_metadata(gem_name, version, root).merge(extra.transform_keys(&:to_s))
    File.write(metadata_path(gem_name, version, root), JSON.generate(data))
    data
  end

  # Decide "changed" by a deterministic diff, never by the model's say-so.
  def apply_verify(gem_name, version, corrected, model:, root: cache_root, now: Time.now)
    path = skill_path(gem_name, version, root)
    raise Error, "No cached skill for #{gem_name} #{version}" unless File.exist?(path)

    current = File.read(path)
    fixed   = build_frontmatter(gem_name, version, corrected.to_s.strip.empty? ? current : strip_wrapper_fence(corrected))
    changed = normalize(fixed) != normalize(build_frontmatter(gem_name, version, current))

    File.write(path, fixed) if changed
    merge_metadata(gem_name, version, { verification: {
      verified: true, verified_at: now.iso8601, model: model, fixed: changed
    } }, root)
    { verified: true, changed: changed }
  end

  def mark_unverifiable(gem_name, version, model:, root: cache_root, now: Time.now)
    merge_metadata(gem_name, version, { verification: {
      verified: false, verified_at: now.iso8601, model: model,
      skipped_reason: "no installed source available"
    } }, root)
    { verified: false, changed: false }
  end

  def list(root = cache_root)
    return [] unless Dir.exist?(root)

    Dir.children(root).sort.flat_map do |gem_name|
      next [] unless File.directory?(File.join(root, gem_name))

      Dir.children(File.join(root, gem_name)).sort.map do |version|
        { gem: gem_name, version: version,
          verified: read_metadata(gem_name, version, root).dig("verification", "verified") == true }
      end
    end
  end

  def purge(gem_name, version, root = cache_root)
    versions = version ? [version] : (Dir.exist?(File.join(root, gem_name)) ? Dir.children(File.join(root, gem_name)) : [])
    versions.each { FileUtils.rm_rf(skill_dir(gem_name, it, root)) }
    parent = File.join(root, gem_name)
    Dir.rmdir(parent) if Dir.exist?(parent) && Dir.empty?(parent)
    { purged: versions.sort.map { "#{gem_name} #{it}" } }
  end

  # --- project links (Linker) --------------------------------------------

  def link(gem_name, version, project_root = Dir.pwd, root = cache_root)
    raise Error, "No cached skill for #{gem_name} #{version}" unless File.exist?(skill_path(gem_name, version, root))

    dir = project_skills_dir(project_root)
    FileUtils.mkdir_p(dir)
    link_path = File.join(dir, gem_name)
    raise Error, "#{link_path} exists and is not a symlink; refusing to replace it" if File.exist?(link_path) && !File.symlink?(link_path)

    File.unlink(link_path) if File.symlink?(link_path)
    File.symlink(skill_dir(gem_name, version, root), link_path)
    { linked: link_path, target: skill_dir(gem_name, version, root) }
  end

  def linked_gems(project_root = Dir.pwd)
    dir = project_skills_dir(project_root)
    return [] unless Dir.exist?(dir)

    Dir.glob(File.join(dir, "*")).filter_map do |path|
      next unless File.symlink?(path)

      target = File.readlink(path)
      { gem: File.basename(path), version: File.basename(target), target: target,
        valid: File.exist?(File.join(target, "SKILL.md")) }
    end
  end

  def prune(project_root = Dir.pwd)
    dead = linked_gems(project_root).reject { it[:valid] }
    dead.each { File.unlink(File.join(project_skills_dir(project_root), it[:gem])) }
    { pruned: dead.map { it[:gem] } }
  end

  # --- Gemfile.lock (Lockfile) -------------------------------------------

  def parse_specs(content)
    in_specs = false
    content.each_line.with_object({}) do |line, specs|
      if line.strip == "specs:"
        in_specs = true
      elsif in_specs && line =~ /\A {4}(\S+) \(([^)]+)\)/
        specs[$1] = $2
      elsif in_specs && line !~ /\A /
        in_specs = false
      end
    end
  end

  def parse_direct_names(content)
    in_deps = false
    content.each_line.with_object([]) do |line, names|
      if line.strip == "DEPENDENCIES"
        in_deps = true
      elsif in_deps && line =~ /\A  (\S+)/
        names << $1
      elsif in_deps && !line.strip.empty?
        in_deps = false
      end
    end
  end

  def parse_path_dep_names(content)
    in_path = in_specs = in_gem = false
    content.each_line.with_object([]) do |line, names|
      if line.strip == "PATH"
        in_path, in_specs, in_gem = true, false, false
      elsif in_path && line.strip == "specs:"
        in_specs = true
      elsif in_path && in_specs && line =~ /\A {4}\S/
        in_gem = true
      elsif in_path && in_specs && in_gem && line =~ /\A {6}(\S+)/
        names << $1
      elsif in_path && !line.start_with?(" ") && !line.strip.empty?
        in_path = in_specs = in_gem = false
      end
    end
  end

  def parse_lockfile(content)
    specs = parse_specs(content)
    (parse_direct_names(content) + parse_path_dep_names(content)).uniq
      .each_with_object({}) { |name, hash| hash[name] = specs[name] if specs.key?(name) }
  end

  def lockfile_gems(path = "Gemfile.lock")
    raise Error, "Gemfile.lock not found at #{path}" unless File.exist?(path)

    parse_lockfile(File.read(path))
  end

  # What `bundle skill refresh` needs: which lockfile gems still need work.
  def status(lockfile = "Gemfile.lock", project_root = Dir.pwd)
    links = linked_gems(project_root).to_h { [it[:gem], it] }
    lockfile_gems(lockfile).map do |gem_name, version|
      link = links[gem_name]
      { gem: gem_name, version: version,
        cached: File.exist?(skill_path(gem_name, version)),
        linked_current: !link.nil? && link[:valid] && link[:version] == version }
    end
  end

  # --- CLI ---------------------------------------------------------------

  def option(args, flag)
    idx = args.index(flag)
    return nil unless idx

    value = args[idx + 1]
    args.slice!(idx, 2)
    value
  end

  def run(argv)
    args = argv.dup
    command = args.shift
    out = option(args, "--out")
    model = option(args, "--model")
    project = option(args, "--project") || Dir.pwd

    case command
    when "resolve"
      resolve(args.fetch(0), args[1])
    when "sources"
      gem_name, version = args.fetch(0), args.fetch(1)
      sources = fetch_sources(gem_name, version)
      raise Error, "No documentation found for #{gem_name} #{version}" if sources.empty?

      path = out || scratch_path(gem_name, version, "sources")
      text = format_sources(sources)
      File.write(path, text)
      { path: path, sources: sources.keys.map(&:to_s), chars: text.length }
    when "source-code"
      gem_name, version = args.fetch(0), args.fetch(1)
      bundle = source_bundle(gem_dir(gem_name, version))
      return { verifiable: false } unless bundle

      path = out || scratch_path(gem_name, version, "source")
      File.write(path, bundle[:code])
      { verifiable: true, path: path, files: bundle[:files].length, chars: bundle[:chars], truncated: bundle[:truncated] }
    when "store"
      sources = (option(args, "--sources") || "").split(",").map(&:strip).reject(&:empty?)
      raise Error, "--model is required" unless model

      store(args.fetch(0), args.fetch(1), File.read(args.fetch(2)), model: model, sources: sources)
    when "apply-verify"
      raise Error, "--model is required" unless model

      if args.delete("--unverifiable")
        mark_unverifiable(args.fetch(0), args.fetch(1), model: model)
      else
        apply_verify(args.fetch(0), args.fetch(1), File.read(args.fetch(2)), model: model)
      end
    when "link"      then link(args.fetch(0), args.fetch(1), project)
    when "lockfile"  then lockfile_gems(args[0] || "Gemfile.lock")
    when "status"    then status(option(args, "--lockfile") || File.join(project, "Gemfile.lock"), project)
    when "prune"     then prune(project)
    when "list"      then list
    when "purge"
      gem_name = args.fetch(0)
      all = args.delete("--all")
      raise Error, "purge needs VERSION or --all" unless all || args[1]

      purge(gem_name, all ? nil : args[1])
    else
      raise Error, "unknown command: #{command.inspect}"
    end
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    $stdout.write(JSON.pretty_generate(GemSkill.run(ARGV)), "\n")
  rescue GemSkill::Error, IndexError, SystemCallError => e
    $stderr.write(JSON.generate(error: e.message), "\n")
    exit 1
  end
end
