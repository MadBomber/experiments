# Architecture - DHH Rails Style

<routing>
## Routing

Everything maps to CRUD. Nested resources for related actions:

```ruby
Rails.application.routes.draw do
  resources :boards do
    resources :cards do
      resource :closure
      resource :goldness
      resource :not_now
      resources :assignments
      resources :comments
    end
  end
end
```

**Multi-tenancy** via URL (not subdomain):
```ruby
# /{account_id}/boards/...
scope "/:account_id" do
  resources :boards
end
```

Benefits:
- No subdomain DNS complexity
- Deep links work naturally
- Middleware extracts account_id, moves to SCRIPT_NAME
- `Current.account` available everywhere
</routing>

<authentication>
## Authentication

Custom passwordless magic link auth (~150 lines total):

```ruby
# app/models/session.rb
class Session < ApplicationRecord
  belongs_to :user

  before_create { self.token = SecureRandom.urlsafe_base64(32) }
end

# app/models/magic_link.rb
class MagicLink < ApplicationRecord
  belongs_to :user

  before_create do
    self.code = SecureRandom.random_number(100_000..999_999).to_s
    self.expires_at = 15.minutes.from_now
  end

  def expired?
    expires_at < Time.current
  end
end
```

**Why not Devise:**
- ~150 lines vs massive dependency
- No password storage liability
- Simpler UX for users
- Full control over flow

**Bearer token** for APIs:
```ruby
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate
  end

  private
    def authenticate
      if bearer_token = request.headers["Authorization"]&.split(" ")&.last
        Current.session = Session.find_by(token: bearer_token)
      else
        Current.session = Session.find_by(id: cookies.signed[:session_id])
      end

      redirect_to login_path unless Current.session
    end
end
```
</authentication>

<background_jobs>
## Background Jobs

Jobs are shallow wrappers calling model methods:

```ruby
class NotifyWatchersJob < ApplicationJob
  def perform(card)
    card.notify_watchers
  end
end
```

**Naming convention:**
- `_later` suffix for async: `card.notify_watchers_later`
- `_now` suffix for immediate: `card.notify_watchers_now`

```ruby
module Watchable
  def notify_watchers_later
    NotifyWatchersJob.perform_later(self)
  end

  def notify_watchers_now
    NotifyWatchersJob.perform_now(self)
  end

  def notify_watchers
    watchers.each do |watcher|
      WatcherMailer.notification(watcher, self).deliver_later
    end
  end
end
```

**Database-backed** with Solid Queue:
- No Redis required
- Same transactional guarantees as your data
- Simpler infrastructure
</background_jobs>

<current_attributes>
## Current Attributes

Use `Current` for request-scoped state:

```ruby
# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user, :account, :request_id

  delegate :user, to: :session, allow_nil: true

  def account=(account)
    super
    Time.zone = account&.time_zone || "UTC"
  end
end
```

Set in controller:
```ruby
class ApplicationController < ActionController::Base
  before_action :set_current_request

  private
    def set_current_request
      Current.session = authenticated_session
      Current.account = Account.find(params[:account_id])
      Current.request_id = request.request_id
    end
end
```

Use throughout app:
```ruby
class Card < ApplicationRecord
  belongs_to :creator, default: -> { Current.user }
end
```
</current_attributes>

<caching>
## Caching

**HTTP caching** with ETags:
```ruby
fresh_when etag: [@card, Current.user.timezone]
```

**Fragment caching:**
```erb
<% cache card do %>
  <%= render card %>
<% end %>
```

**Russian doll caching:**
```erb
<% cache @board do %>
  <% @board.cards.each do |card| %>
    <% cache card do %>
      <%= render card %>
    <% end %>
  <% end %>
<% end %>
```

**Cache invalidation** via `touch: true`:
```ruby
class Card < ApplicationRecord
  belongs_to :board, touch: true
end
```

**Solid Cache** - database-backed:
- No Redis required
- Consistent with application data
- Simpler infrastructure
</caching>

<configuration>
## Configuration

**ENV.fetch with defaults:**
```ruby
# config/application.rb
config.active_job.queue_adapter = ENV.fetch("QUEUE_ADAPTER", "solid_queue").to_sym
config.cache_store = ENV.fetch("CACHE_STORE", "solid_cache").to_sym
```

**Multiple databases:**
```yaml
# config/database.yml
production:
  primary:
    <<: *default
  cable:
    <<: *default
    migrations_paths: db/cable_migrate
  queue:
    <<: *default
    migrations_paths: db/queue_migrate
  cache:
    <<: *default
    migrations_paths: db/cache_migrate
```

**Switch between SQLite and MySQL via ENV:**
```ruby
adapter = ENV.fetch("DATABASE_ADAPTER", "sqlite3")
```

**CSP extensible via ENV:**
```ruby
config.content_security_policy do |policy|
  policy.default_src :self
  policy.script_src :self, *ENV.fetch("CSP_SCRIPT_SRC", "").split(",")
end
```
</configuration>

<testing>
## Testing

**Minitest**, not RSpec:
```ruby
class CardTest < ActiveSupport::TestCase
  test "closing a card creates a closure" do
    card = cards(:one)

    card.close

    assert card.closed?
    assert_not_nil card.closure
  end
end
```

**Fixtures** instead of factories:
```yaml
# test/fixtures/cards.yml
one:
  title: First Card
  board: main
  creator: alice

two:
  title: Second Card
  board: main
  creator: bob
```

**Integration tests** for controllers:
```ruby
class CardsControllerTest < ActionDispatch::IntegrationTest
  test "closing a card" do
    card = cards(:one)
    sign_in users(:alice)

    post card_closure_path(card)

    assert_response :success
    assert card.reload.closed?
  end
end
```

**Tests ship with features** - same commit, not TDD-first but together.

**Regression tests for security fixes** - always.
</testing>

<events>
## Event Tracking

Events are the single source of truth:

```ruby
class Event < ApplicationRecord
  belongs_to :creator, class_name: "User"
  belongs_to :eventable, polymorphic: true

  serialize :particulars, coder: JSON
end
```

**Eventable concern:**
```ruby
module Eventable
  extend ActiveSupport::Concern

  included do
    has_many :events, as: :eventable, dependent: :destroy
  end

  def record_event(action, particulars = {})
    events.create!(
      creator: Current.user,
      action: action,
      particulars: particulars
    )
  end
end
```

**Webhooks driven by events** - events are the canonical source.
</events>
