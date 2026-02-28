# Rails Refactoring Skills

> **Goal:** Maintainable, performant, and idiomatic code.
> **Philosophy:** Leave the campground cleaner than you found it.

## 1. Common Rails Code Smells

### Fat Controllers
**Sign:** Action methods > 10 lines. Complex branching.
**Fix:** Extract logic to **Interactions** or **Form Objects**.

### God Models
**Sign:** `User.rb` is 500+ lines. Too many `has_many`.
**Fix:** Extract **Concerns** (`User::Searchable`, `User::Authenticatable`) or split into Value Objects.

### Callback Hell
**Sign:** `before_save :update_total`, `after_create :send_email`, `after_commit :sync_crm`.
**Risk:** Side effects are hard to debug and test. infinite loops.
**Fix:** Remove callbacks. Trigger explicit **Interactions** from the Controller.

## 2. Refactoring Patterns

### Extract Query Object
**Before:**
```ruby
# Controller
@users = User.where(active: true).where("age > ?", 18).order(:created_at)
```

**After:**
```ruby
# app/queries/adult_users_query.rb
class AdultUsersQuery
  def self.call
    User.active.where("age > ?", 18).order(:created_at)
  end
end
```

### Extract Form Object
**Use when:** A form updates multiple models (User + Profile + Settings).
**Tool:** `ActiveModel::Model` or `Reform`.

### Extract Service/Interaction
**Use when:** Business logic spans multiple models (e.g., "Place Order" involves Order, Payment, Inventory, Email).

## 3. Modernization Checklist

- **Time:** Replace `Date.today` / `Time.now` -> `Time.current` / `Date.current` (Timezone safety).
- **Fetch:** Replace `params[:key]` -> `params.fetch(:key)` (Fail fast).
- **Safety:** Replace `update_attributes` -> `update`.
- **Enums:** Replace magic strings/integers with `enum`.
- **Bool:** Replace `user.admin == true` -> `user.admin?`.

## 4. Technical Debt Audit
When analyzing a legacy codebase, look for:
1.  **Unused Routes:** Run `rails routes` and compare with logs.
2.  **Dead Code:** Unused private methods or scopes.
3.  **Slow Tests:** Use `rspec --profile` to find bottlenecks.
4.  **N+1 Queries:** Use `bullet` or manual inspection of logs.
