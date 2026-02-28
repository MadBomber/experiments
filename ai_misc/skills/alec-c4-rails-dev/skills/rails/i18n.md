# Internationalization (i18n) & Localization (l10n)

> **Philosophy:** English is just another locale. No hardcoded strings.
> **Gems:** `i18n-tasks`, `rails-i18n`.

## 1. Strings & Translations
**Rule:** Never use hardcoded strings in Views, Controllers, or Models.

### Lazy Lookup (Views)
Use the `.` shortcut to map to the folder structure.
```erb
<!-- app/views/posts/index.html.erb -->
<h1><%= t('.title') %></h1>
<!-- maps to en.posts.index.title -->
```

### Models & Attributes
Use `config/locales/models/en.yml` for attribute names (handled by Rails automatically).

### Management (`i18n-tasks`)
Use `i18n-tasks` to find missing or unused keys.
- `i18n-tasks health`: The ultimate check.
- `i18n-tasks add-missing`: Auto-fill missing keys.

## 2. Timezones
**Rule:** The Server lives in UTC. The User lives in `Time.zone`.

### DO NOT USE
- `Time.now` (Uses system time, ignores Rails config).
- `Date.today` (Can be yesterday in user's timezone).

### DO USE
- `Time.current` (Respects `Time.zone`).
- `Date.current`
- `user.created_at.in_time_zone(current_user.time_zone)`

### Setup
1.  Add `time_zone` column to Users table.
2.  Set `Time.zone` in `ApplicationController` around action.

```ruby
around_action :set_time_zone

def set_time_zone(&block)
  Time.use_zone(current_user&.time_zone || "UTC", &block)
end
```

## 3. Formatting (Numbers & Currency)
Never manually format strings.
- **Dates:** `<%= l(timestamp, format: :short) %>`
- **Currency:** `<%= number_to_currency(amount) %>`
- **Numbers:** `<%= number_with_delimiter(count) %>`
