# Ruby Gems Skills

> **Scope:** Gemfile management, Gem creation, and Rails Engines.
> **Standard:** Semantic Versioning (SemVer).

## 1. Consuming Gems (Gemfile)

### Versioning Strategies
Always use **Pessimistic Version Constraint** (`~>`) for libraries to allow patch/minor updates but prevent breaking changes.

```ruby
# Good: Allows 3.2.1, 3.2.9, but NOT 3.3.0
gem "shakapacker", "~> 3.2.0"

# Good: Allows 7.1.x, but NOT 7.2.0 (safer for frameworks)
gem "rails", "~> 7.1.0"
```

### Grouping
Minimize memory footprint in production by grouping dev/test gems.

```ruby
group :development, :test do
  gem "rspec-rails"
  gem "debug"
  gem "brakeman"
end

group :test do
  gem "simplecov", require: false
end
```

## 2. Creating Gems

### Initialization
Use Bundler to scaffold:
`bundle gem my_library --test=rspec --linter=rubocop --mit`

### The Gemspec
Keep metadata clean. Avoid "TODO" strings.

```ruby
# my_library.gemspec
spec.name        = "my_library"
spec.version     = MyLibrary::VERSION
spec.authors     = ["Alec"]
spec.summary     = "A short summary."
spec.description = "A longer description."
spec.homepage    = "https://github.com/user/my_library"

# Dependencies
# runtime_dependency: What your gem NEEDS to run
spec.add_dependency "activesupport", ">= 7.0"

# development_dependency: Tools for developing your gem
spec.metadata["rubygems_mfa_required"] = "true"
```

### Loading Code
- **Main file (`lib/my_library.rb`):** Should strictly `require` dependencies and sub-files.
- **Zeitwerk:** Modern gems should use Zeitwerk for autoloading if possible, or careful `require_relative`.

## 3. Rails Engines (Modular Rails)

Use Engines to extract complex domains (e.g., `Forum`, `Store`) into reusable packages.

**Generate:**
`rails plugin new my_engine --mountable --dummy-path=spec/dummy`

**Mounting (`config/routes.rb`):**
`mount MyEngine::Engine => "/my_engine"`

**Best Practice:**
- Keep engine logic isolated.
- Expose a configuration block for the main app to hook into.

```ruby
# lib/my_engine.rb
module MyEngine
  mattr_accessor :user_class
  
  def self.setup
    yield self
  end
end

# In Main App initializer
MyEngine.setup do |config|
  config.user_class = "User"
end
```

## 4. Release & Security

### Publishing
1.  **Build:** `gem build my_library.gemspec`
2.  **Push:** `gem push my_library-1.0.0.gem`

### Security
- **MFA:** Enforce MFA for publishing.
- **Audit:** Regular `bundle audit` checks.
- **Trusted Publishing:** Use GitHub Actions OIDC for automated PyPI/RubyGems publishing without long-lived secrets.
