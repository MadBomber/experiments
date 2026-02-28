# Rails Core Patterns

> **Scope:** Models, Controllers, Routing, Active Record
> **Conventions:** Latest Stable (Rails 7.1+, 8.0+)

## 1. Models (Active Record)
- **Validations:** standard Rails validations.
- **Associations:** Always define both sides (`has_many` / `belongs_to`).
- **Scopes:** Use `scope :name, -> { ... }` (never class methods for scopes).
- **Enums:** `enum status: { pending: 0, active: 1 }` (use explicit mapping).

## 2. Controllers
- **Resourceful:** Stick to `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`.
- **Non-Standard Actions:** If you need `post :publish`, consider a separate controller `Posts::PublicationsController#create`.
- **Response:** Respond to `html` and `turbo_stream` by default.

## 3. Business Logic
Check `skills/architecture` for the project preference (Interactions vs Services).
- Default: **ActiveInteraction** (if gem present).
- Fallback: **Service Objects** (`app/services/user_creator.rb`).

## 4. Solid Stack (Rails 8)
- **Queues:** Solid Queue.
- **Cache:** Solid Cache.
- **Cable:** Solid Cable.
