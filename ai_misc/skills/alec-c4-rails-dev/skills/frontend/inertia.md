# Inertia.js Skills (Svelte, React, Vue)

> **Scope:** Monolith with SPA experience.

## 1. Controller Integration
Use `render inertia:` instead of `render :show`.

```ruby
def index
  @posts = Post.all
  render inertia: "Posts/Index", props: {
    posts: @posts.as_json(only: [:id, :title])
  }
end
```

## 2. Shared Data
Configure global props (flash messages, user auth) in `application_controller.rb`.

```ruby
class ApplicationController < ActionController::Base
  inertia_share do
    {
      flash: flash.to_hash,
      auth: { user: current_user&.as_json }
    }
  end
end
```

## 3. Frontend Selection (Adapter)
- **React:** Standard, large ecosystem.
- **Svelte:** Highly performant, less boilerplate.
- **Vue:** Familiar for Rails devs (similar to Stimulus/ERB logic).

## 4. SSR (Server Side Rendering)
Enable SSR for SEO in `config/initializers/inertia_rails.rb`.

## 5. Forms
Use the `useForm` hook provided by Inertia adapters for handling validation errors automatically.
