# Ruby Style & Linting

> **Standard:** [Standard Ruby](https://github.com/testdouble/standard) (Opinionated RuboCop wrapper)
> **Goal:** Consistency without bikeshedding.

## 1. Setup
Use `standard` gem instead of raw `rubocop` configuration where possible, or inherit from it.

```ruby
# Gemfile
group :development, :test do
  gem "standard"
  gem "rubocop-rails"
  gem "rubocop-rspec"
  gem "rubocop-performance"
end
```

## 2. Configuration (`.rubocop.yml`)

```yaml
require:
  - standard
  - rubocop-rails
  - rubocop-rspec
  - rubocop-performance

inherit_gem:
  standard: config/base.yml

AllCops:
  NewCops: enable
  Exclude:
    - db/schema.rb
    - node_modules/**/*
    - bin/**/*
```

## 3. Rules to Enforce
- **Double quotes** preferred (Standard default).
- **Trailing commas** in multiline arrays/hashes (Standard default).
- **Service Objects:** Use `call` or `run`, not `execute` or `perform` (unless using ActiveInteraction).

## 4. Autofix
Run `bundle exec standardrb --fix` to automatically format code.
