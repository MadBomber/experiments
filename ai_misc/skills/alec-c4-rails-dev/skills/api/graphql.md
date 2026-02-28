# GraphQL Skills for Rails

> **Gem:** `graphql-ruby`
> **Standards:** Clean types, mutations, N+1 prevention.

## 1. Type Definitions
Always use descriptive names and define nullability correctly.

```ruby
module Types
  class PostType < Types::BaseObject
    field :id, ID, null: false
    field :title, String, null: false
    field :content, String, null: true
    field :author, Types::UserType, null: false
  end
end
```

## 2. Preventing N+1 (DataLoader)
Never fetch associations directly in fields. Use **DataLoader**.

```ruby
field :comments, [Types::CommentType], null: false

def comments
  dataloader.with(Sources::ActiveRecord, Comment).load_all(object.comment_ids)
end
```

## 3. Mutations
Use `BaseMutation` and return both the object and errors.

```ruby
module Mutations
  class CreatePost < BaseMutation
    argument :title, String, required: true
    
    field :post, Types::PostType, null: true
    field :errors, [String], null: false

    def resolve(title:)
      post = Post.new(title: title, author: context[:current_user])
      if post.save
        { post: post, errors: [] }
      else
        { post: nil, errors: post.errors.full_messages }
      end
    end
  end
end
```

## 4. Best Practices
- **Input Objects:** Use `InputObject` for mutations with many arguments.
- **Complexity:** Define `complexity` on expensive fields.
- **Testing:** Use `execute` on the schema for unit testing.
