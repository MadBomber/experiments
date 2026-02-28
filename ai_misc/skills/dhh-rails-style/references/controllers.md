# Controllers - DHH Rails Style

<rest_mapping>
## Everything Maps to CRUD

Custom actions become new resources. Instead of verbs on existing resources, create noun resources:

```ruby
# Instead of this:
POST /cards/:id/close
DELETE /cards/:id/close
POST /cards/:id/archive

# Do this:
POST /cards/:id/closure      # create closure
DELETE /cards/:id/closure    # destroy closure
POST /cards/:id/archival     # create archival
```

**Real examples from 37signals:**
```ruby
resources :cards do
  resource :closure       # closing/reopening
  resource :goldness      # marking important
  resource :not_now       # postponing
  resources :assignments  # managing assignees
end
```

Each resource gets its own controller with standard CRUD actions.
</rest_mapping>

<controller_concerns>
## Concerns for Shared Behavior

Controllers use concerns extensively. Common patterns:

**CardScoped** - loads @card, @board, provides render_card_replacement
```ruby
module CardScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_card
  end

  private
    def set_card
      @card = Card.find(params[:card_id])
      @board = @card.board
    end

    def render_card_replacement
      render turbo_stream: turbo_stream.replace(@card)
    end
end
```

**BoardScoped** - loads @board
**CurrentRequest** - populates Current with request data
**CurrentTimezone** - wraps requests in user's timezone
**FilterScoped** - handles complex filtering
**TurboFlash** - flash messages via Turbo Stream
**ViewTransitions** - disables on page refresh
</controller_concerns>

<turbo_responses>
## Turbo Stream Responses

Use Turbo Streams for partial updates:

```ruby
class Cards::ClosuresController < ApplicationController
  include CardScoped

  def create
    @card.close
    render_card_replacement
  end

  def destroy
    @card.reopen
    render_card_replacement
  end
end
```

For complex updates, use morphing:
```ruby
render turbo_stream: turbo_stream.morph(@card)
```
</turbo_responses>

<api_patterns>
## API Design

Same controllers, different format. Convention for responses:

```ruby
def create
  @card = Card.create!(card_params)

  respond_to do |format|
    format.html { redirect_to @card }
    format.json { head :created, location: @card }
  end
end

def update
  @card.update!(card_params)

  respond_to do |format|
    format.html { redirect_to @card }
    format.json { head :no_content }
  end
end

def destroy
  @card.destroy

  respond_to do |format|
    format.html { redirect_to cards_path }
    format.json { head :no_content }
  end
end
```

**Status codes:**
- Create: 201 Created + Location header
- Update: 204 No Content
- Delete: 204 No Content
- Bearer token authentication
</api_patterns>

<http_caching>
## HTTP Caching

Extensive use of ETags and conditional GETs:

```ruby
class CardsController < ApplicationController
  def show
    @card = Card.find(params[:id])
    fresh_when etag: [@card, Current.user.timezone]
  end

  def index
    @cards = @board.cards.preloaded
    fresh_when etag: [@cards, @board.updated_at]
  end
end
```

Key insight: Times render server-side in user's timezone, so timezone must affect the ETag to prevent serving wrong times to other timezones.

**ApplicationController global etag:**
```ruby
class ApplicationController < ActionController::Base
  etag { "v1" }  # Bump to invalidate all caches
end
```

Use `touch: true` on associations for cache invalidation.
</http_caching>
