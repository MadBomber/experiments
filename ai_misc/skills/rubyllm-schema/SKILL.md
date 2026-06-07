---
name: rubyllm/schema
version: 0.3.0
description: |
  Ruby DSL for JSON Schema creation. Use this skill when defining structured data schemas for LLM function calling or structured outputs with RubyLLM. Provides Rails-inspired API for creating complex nested schemas.
---

# RubyLLM::Schema v{{ page.version }}

**Ruby DSL for JSON Schema Creation**

A clean, Rails-inspired API for creating JSON schemas. Perfect for structured data schemas for LLM function calling or structured outputs.

**Gem Version:** 0.3.0
**GitHub:** https://github.com/danielfriis/ruby_llm-schema

## Installation

```bash
gem 'ruby_llm-schema'
```

## Basic Usage

```ruby
class PersonSchema < RubyLLM::Schema
  string :name, description: "Person's full name"
  integer :age, description: "Age in years", minimum: 0, maximum: 120
  boolean :active, required: false

  object :address do
    string :street
    string :city
    string :country, required: false
  end

  array :tags, of: :string, description: "User tags"

  array :contacts do
    object do
      string :email, format: "email"
      string :phone, required: false
    end
  end

  any_of :status do
    string enum: ["active", "pending", "inactive"]
    null
  end
end

puts PersonSchema.to_json_schema
```

## With RubyLLM

```ruby
class PersonSchema < RubyLLM::Schema
  string :name, description: "Person's full name"
  integer :age, description: "Person's age in years"
  string :city, required: false, description: "City where they live"
end

chat = RubyLLM.chat
response = chat.with_schema(PersonSchema)
  .ask("Generate a person named Alice who is 30 years old")

puts response.content        # => {"name" => "Alice", "age" => 30}
puts response.content.class  # => Hash
```

## Type Helpers

### Primitive Types

```ruby
string :name, description: "Full name"
integer :age, minimum: 0, maximum: 120
number :price, minimum: 0.0
boolean :active, default: true
null :optional_field
```

### Complex Types

```ruby
object :address do
  string :street
  string :city
  string :country
end

array :tags, of: :string
array :scores, of: :number

array :contacts do
  object do
    string :email, format: "email"
    string :phone
  end
end

any_of :value do
  string
  integer
  null
end
```

### Enums

```ruby
string :status, enum: ["active", "pending", "inactive"]

any_of :priority do
  string enum: ["low", "medium", "high"]
  null
end
```

## Options

All type helpers accept:

- `description` - Schema description
- `required` - Whether field is required (default: true)
- `default` - Default value
- `enum` - Array of allowed values
- `format` - String format (email, uri, date-time, etc.)
- `minimum`/`maximum` - For numbers
- `min_length`/`max_length` - For strings

```ruby
string :email,
  description: "User email address",
  format: "email",
  min_length: 5,
  max_length: 255

number :price,
  minimum: 0,
  maximum: 10000,
  default: 0.0
```

## Advanced Features

### Schema Definitions (Reusable Components)

```ruby
class ProductSchema < RubyLLM::Schema
  definition :money do
    object do
      number :amount
      string :currency, enum: ["USD", "EUR", "GBP"]
    end
  end

  string :name
  ref :price, definition: :money
end
```

### Inheritance

```ruby
class BaseSchema < RubyLLM::Schema
  string :id
end

class UserSchema < BaseSchema
  string :name
  string :email
end
```

### Strict Mode

```ruby
class StrictSchema < RubyLLM::Schema
  strict true  # additionalProperties: false

  string :name
end
```

## Practical Examples

### Code Review Schema

```ruby
class ReviewSchema < RubyLLM::Schema
  object :review do
    string :summary
    array :issues do
      object do
        string :severity, enum: ["critical", "major", "minor"]
        string :location
        string :suggestion
      end
    end
    integer :score, description: "1-10"
  end
end
```

### Article Metadata Extraction

```ruby
class ArticleSchema < RubyLLM::Schema
  string :title
  array :topics, of: :string
  string :summary, description: "2-3 sentence summary"
  string :sentiment, enum: ["positive", "neutral", "negative"]
end

chat.with_schema(ArticleSchema)
  .ask("Extract metadata from this article: #{content}")
```

### Structured Actions

```ruby
class ActionSchema < RubyLLM::Schema
  string :action_type, enum: ["email", "call", "meeting", "task"]
  string :assignee
  object :context do
    string :priority
    array :dependencies, of: :string
  end
end
```

## See Also

- **Main RubyLLM**: [rubyllm](../rubyllm/SKILL.md)
- **Source**: https://github.com/danielfriis/ruby_llm-schema
