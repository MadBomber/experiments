# Hotwire Skills (Turbo & Stimulus)

> **Scope:** Server-Side Rendering (SSR) with dynamic updates.

## 1. Turbo Drive
- Enabled by default.
- **Link Prefetching:** Use `data-turbo-prefetch="true"` on hoverable links.
- **Form Submission:** Returns `422 Unprocessable Entity` on validation errors.

## 2. Turbo Frames
Use for isolated parts of the page (e.g., in-line editing, modals).

```erb
<%= turbo_frame_tag "post_#{@post.id}" do %>
  <!-- Content here -->
<% end %>
```

## 3. Turbo Streams
Use for real-time updates (WebSockets) or response updates without full reload.

**Controller:**
```ruby
def create
  @comment = Comment.create!(params)
  respond_to do |format|
    format.turbo_stream
    format.html { redirect_to @comment.post }
  end
end
```

**View (`create.turbo_stream.erb`):**
```erb
<%= turbo_stream.prepend "comments", partial: "comments/comment", locals: { comment: @comment } %>
<%= turbo_stream.update "new_comment", partial: "comments/form" %>
```

## 4. Stimulus
Use for client-side behavior (toggles, masking, datepickers).
**Naming:** `kebab-case` controller names.

```javascript
// app/javascript/controllers/clipboard_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source"]

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.value)
  }
}
```
