---
name: rubyllm-moderation
description: |
  Content safety checking with RubyLLM. Use this skill to identify potentially harmful content in text before sending to LLMs, screen user inputs, and moderate AI outputs for safety.
---

# RubyLLM Moderation

Identify potentially harmful content in text using AI moderation models.

**v1.8.0+**

## Basic Usage

```ruby
# Moderate text
result = RubyLLM.moderate("This is a safe message about Ruby programming")

# Check if flagged
if result.flagged?
  puts "Flagged categories: #{result.flagged_categories.join(', ')}"
else
  puts "Content is safe"
end

# Access full results
puts "Moderation ID: #{result.id}"
puts "Model used: #{result.model}"
puts "Results: #{result.results}"
```

## Category Scores

Scores range from 0.0 to 1.0 (higher = more likely):

```ruby
result = RubyLLM.moderate("Some user input text")

scores = result.category_scores
puts "Sexual content: #{scores['sexual']}"
puts "Harassment: #{scores['harassment']}"
puts "Violence: #{scores['violence']}"
puts "Hate speech: #{scores['hate']}"
puts "Self-harm: #{scores['self-harm']}"

# Boolean flags
categories = result.categories
puts "Contains hate speech: #{categories['hate']}"
puts "Contains harassment: #{categories['harassment']}"
```

## Use Cases

### Pre-Screen User Input

```ruby
def safe_ask(chat, question)
  mod = RubyLLM.moderate(question)
  
  if mod.flagged?
    Rails.logger.warn "Unsafe user input: #{mod.flagged_categories.join(', ')}"
    raise "Content violates safety policy"
  end
  
  chat.ask(question)
end
```

### Screen AI Output

```ruby
response = chat.ask(question)

mod = RubyLLM.moderate(response.content)
if mod.flagged?
  Rails.logger.error "AI generated unsafe content: #{mod.flagged_categories.join(', ')}"
  raise "AI output failed safety check"
end
```

### Custom Thresholds

```ruby
result = RubyLLM.moderate(text)

# Reject if any score > 0.5
unsafe = result.category_scores.any? { |_, score| score > 0.5 }
raise "Content too risky" if unsafe

# Or per-category thresholds
if result.category_scores['hate'] > 0.3
  raise "Hate speech detected"
end

if result.category_scores['violence'] > 0.7
  raise "Violent content"
end
```

### Content Scoring

```ruby
class ContentSafety
  SCORES = {
    sexual: 0.5,
    harassment: 0.6,
    violence: 0.7,
    hate: 0.3,  # Zero tolerance
    self_harm: 0.4
  }.freeze
  
  def self.safe?(text)
    result = RubyLLM.moderate(text)
    return true unless result.flagged?
    
    SCORES.all? do |category, threshold|
      score = result.category_scores[category.to_s] || 0
      score <= threshold
    end
  end
  
  def self.risk_score(text)
    result = RubyLLM.moderate(text)
    result.category_scores.values.sum / result.category_scores.size
  end
end

# Usage
if ContentSafety.safe?(user_input)
  chat.ask(user_input)
else
  render plain: "Content violates safety policy", status: :bad_request
end
```

## Models

| Model | Provider | Categories |
|-------|----------|------------|
| omni-moderation-latest | OpenAI | 11 categories |
| text-moderation-stable | OpenAI | Legacy model |

```ruby
# Latest model (default)
RubyLLM.moderate("text")

# Specific model
RubyLLM.moderate("text", model: 'omni-moderation-latest')
```

## Categories

Standard categories:

- `sexual` - Sexual content
- `hate` - Hate speech
- `harassment` - Harassment
- `self-harm` - Self-harm content
- `sexual/minors` - Sexual content involving minors
- `hate/threatening` - Threatening hate speech
- `violence/graphic` - Graphic violence
- `self-harm/intent` - Self-harm intent
- `self-harm/instructions` - Self-harm instructions
- `violence` - Violence
- `harassment/threatening` - Threatening harassment

## Rails Integration

```ruby
# app/models/concerns/content_moderation.rb
module ContentModeration
  extend ActiveSupport::Concern
  
  included do
    validate :moderate_content
  end
  
  private
  
  def moderate_content
    return unless content_changed? && content.present?
    
    result = RubyLLM.moderate(content)
    
    if result.flagged?
      errors.add(:content, "contains unsafe content: #{result.flagged_categories.join(', ')}")
    end
  end
end

# app/models/comment.rb
class Comment < ApplicationRecord
  include ContentModeration
  
  validates :content, presence: true
end
```

## Async Moderation

```ruby
# Don't block on moderation
class ModerationJob < ApplicationJob
  def perform(record_class, record_id)
    record = record_class.constantize.find(record_id)
    result = RubyLLM.moderate(record.content)
    
    if result.flagged?
      record.update!(status: :flagged, moderation_result: result.results)
      ModerationAlert.notify(record)
    else
      record.update!(status: :approved)
    end
  end
end

# Usage
Comment.create!(content: text)
ModerationJob.perform_later('Comment', comment.id)
```

## See Also

- **Main RubyLLM**: [rubyllm](../SKILL.md)
- **Tools**: [tools](../tools/SKILL.md) - Building safe tools
