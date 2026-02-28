# Frontend - DHH Rails Style

<turbo_patterns>
## Turbo Patterns

**Turbo Streams** for partial updates:
```erb
<%# app/views/cards/closures/create.turbo_stream.erb %>
<%= turbo_stream.replace @card %>
```

**Morphing** for complex updates:
```ruby
render turbo_stream: turbo_stream.morph(@card)
```

**Fragment caching** with `cached: true`:
```erb
<%= render partial: "card", collection: @cards, cached: true %>
```

**No ViewComponents** - standard partials work fine.
</turbo_patterns>

<stimulus_controllers>
## Stimulus Controllers

52 controllers in Fizzy, split 62% reusable, 38% domain-specific.

**Characteristics:**
- Single responsibility per controller
- Configuration via values/classes
- Events for communication
- Private methods with #
- Most under 50 lines

**Examples:**

```javascript
// copy-to-clipboard (25 lines)
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { content: String }

  copy() {
    navigator.clipboard.writeText(this.contentValue)
    this.#showFeedback()
  }

  #showFeedback() {
    this.element.classList.add("copied")
    setTimeout(() => this.element.classList.remove("copied"), 1500)
  }
}
```

```javascript
// auto-click (7 lines)
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.click()
  }
}
```

```javascript
// toggle-class (31 lines)
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static classes = ["toggle"]
  static values = { open: { type: Boolean, default: false } }

  toggle() {
    this.openValue = !this.openValue
  }

  openValueChanged() {
    this.element.classList.toggle(this.toggleClass, this.openValue)
  }
}
```

```javascript
// dialog (64 lines) - for modal dialogs
// local-save (59 lines) - localStorage persistence
// drag-and-drop (150 lines) - the largest, still reasonable
```
</stimulus_controllers>

<css_architecture>
## CSS Architecture

Vanilla CSS with modern features, no preprocessors.

**CSS @layer** for cascade control:
```css
@layer reset, base, components, modules, utilities;

@layer reset {
  *, *::before, *::after { box-sizing: border-box; }
}

@layer base {
  body { font-family: var(--font-sans); }
}

@layer components {
  .btn { /* button styles */ }
}

@layer modules {
  .card { /* card module styles */ }
}

@layer utilities {
  .hidden { display: none; }
}
```

**OKLCH color system** for perceptual uniformity:
```css
:root {
  --color-primary: oklch(60% 0.15 250);
  --color-success: oklch(65% 0.2 145);
  --color-warning: oklch(75% 0.15 85);
  --color-danger: oklch(55% 0.2 25);
}
```

**Dark mode** via CSS variables:
```css
:root {
  --bg: oklch(98% 0 0);
  --text: oklch(20% 0 0);
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg: oklch(15% 0 0);
    --text: oklch(90% 0 0);
  }
}
```

**Native CSS nesting:**
```css
.card {
  padding: var(--space-4);

  & .title {
    font-weight: bold;
  }

  &:hover {
    background: var(--bg-hover);
  }
}
```

**~60 minimal utilities** vs Tailwind's hundreds.

**Modern features used:**
- `@starting-style` for enter animations
- `color-mix()` for color manipulation
- `:has()` for parent selection
- Logical properties (`margin-inline`, `padding-block`)
- Container queries
</css_architecture>

<view_patterns>
## View Patterns

**Standard partials** - no ViewComponents:
```erb
<%# app/views/cards/_card.html.erb %>
<article id="<%= dom_id(card) %>" class="card">
  <%= render "cards/header", card: card %>
  <%= render "cards/body", card: card %>
  <%= render "cards/footer", card: card %>
</article>
```

**Fragment caching:**
```erb
<% cache card do %>
  <%= render "cards/card", card: card %>
<% end %>
```

**Collection caching:**
```erb
<%= render partial: "card", collection: @cards, cached: true %>
```

**Simple component naming** - no strict BEM:
```css
.card { }
.card .title { }
.card .actions { }
.card.golden { }
.card.closed { }
```
</view_patterns>
