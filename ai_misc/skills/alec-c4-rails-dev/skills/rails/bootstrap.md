# Rails Project Bootstrapping

> **Tool:** `kickstart` templates or `rails new` manual setup.
> **Goal:** Production-ready from Day 1.

## 1. The Stack (Kickstart Default)
- **Database:** PostgreSQL (UUID primary keys).
- **CSS:** Tailwind CSS.
- **JS:** Importmap (Simple) or Esbuild (Complex).
- **Testing:** RSpec.
- **Components:** ViewComponent + Lookbook.
- **Utils:** Solid Queue, Solid Cache.

## 2. One-Liner Setup
If creating a fresh app, use the Kickstart template:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/alec-c4/kickstart/master/install.sh)" -- myapp importmap_tailwind
```

## 3. Manual Checklist (If not using template)

### UUIDs
Enable UUIDs by default in `config/application.rb` generators.
```ruby
config.generators do |g|
  g.orm :active_record, primary_key_type: :uuid
end
```

### Tailwind
Install via `tailwinds-rails`.
```bash
./bin/bundle add tailwindcss-rails
./bin/rails tailwindcss:install
```

### RSpec
Install via `rspec-rails`.
```bash
./bin/rails generate rspec:install
```
