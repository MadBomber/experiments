# Models - DHH Rails Style

<model_concerns>
## Concerns for Horizontal Behavior

Models heavily use concerns. A typical Card model includes 14+ concerns:

```ruby
class Card < ApplicationRecord
  include Assignable
  include Attachments
  include Broadcastable
  include Closeable
  include Colored
  include Eventable
  include Golden
  include Mentions
  include Multistep
  include Pinnable
  include Postponable
  include Readable
  include Searchable
  include Taggable
  include Watchable
end
```

Each concern is self-contained with associations, scopes, and methods.

**Naming:** Adjectives describing capability (`Closeable`, `Publishable`, `Watchable`)
</model_concerns>

<state_records>
## State as Records, Not Booleans

Instead of boolean columns, create separate records:

```ruby
# Instead of:
closed: boolean
is_golden: boolean
postponed: boolean

# Create records:
class Card::Closure < ApplicationRecord
  belongs_to :card
  belongs_to :creator, class_name: "User"
end

class Card::Goldness < ApplicationRecord
  belongs_to :card
  belongs_to :creator, class_name: "User"
end

class Card::NotNow < ApplicationRecord
  belongs_to :card
  belongs_to :creator, class_name: "User"
end
```

**Benefits:**
- Automatic timestamps (when it happened)
- Track who made changes
- Easy filtering via joins and `where.missing`
- Enables rich UI showing when/who

**In the model:**
```ruby
module Closeable
  extend ActiveSupport::Concern

  included do
    has_one :closure, dependent: :destroy
  end

  def closed?
    closure.present?
  end

  def close(creator: Current.user)
    create_closure!(creator: creator)
  end

  def reopen
    closure&.destroy
  end
end
```

**Querying:**
```ruby
Card.joins(:closure)         # closed cards
Card.where.missing(:closure) # open cards
```
</state_records>

<callbacks>
## Callbacks - Used Sparingly

Only 38 callback occurrences across 30 files in Fizzy. Guidelines:

**Use for:**
- `after_commit` for async work
- `before_save` for derived data
- `after_create_commit` for side effects

**Avoid:**
- Complex callback chains
- Business logic in callbacks
- Synchronous external calls

```ruby
class Card < ApplicationRecord
  after_create_commit :notify_watchers_later
  before_save :update_search_index, if: :title_changed?

  private
    def notify_watchers_later
      NotifyWatchersJob.perform_later(self)
    end
end
```
</callbacks>

<scopes>
## Scope Naming

Standard scope names:

```ruby
class Card < ApplicationRecord
  scope :chronologically, -> { order(created_at: :asc) }
  scope :reverse_chronologically, -> { order(created_at: :desc) }
  scope :alphabetically, -> { order(title: :asc) }
  scope :latest, -> { reverse_chronologically.limit(10) }

  # Standard eager loading
  scope :preloaded, -> { includes(:creator, :assignees, :tags) }

  # Parameterized
  scope :indexed_by, ->(column) { order(column => :asc) }
  scope :sorted_by, ->(column, direction = :asc) { order(column => direction) }
end
```
</scopes>

<poros>
## Plain Old Ruby Objects

POROs namespaced under parent models:

```ruby
# app/models/event/description.rb
class Event::Description
  def initialize(event)
    @event = event
  end

  def to_s
    # Presentation logic for event description
  end
end

# app/models/card/eventable/system_commenter.rb
class Card::Eventable::SystemCommenter
  def initialize(card)
    @card = card
  end

  def comment(message)
    # Business logic
  end
end

# app/models/user/filtering.rb
class User::Filtering
  # View context bundling
end
```

**NOT used for service objects.** Business logic stays in models.
</poros>

<verbs_predicates>
## Method Naming

**Verbs** - Actions that change state:
```ruby
card.close
card.reopen
card.gild      # make golden
card.ungild
board.publish
board.archive
```

**Predicates** - Queries derived from state:
```ruby
card.closed?    # closure.present?
card.golden?    # goldness.present?
board.published?
```

**Avoid** generic setters:
```ruby
# Bad
card.set_closed(true)
card.update_golden_status(false)

# Good
card.close
card.ungild
```
</verbs_predicates>
