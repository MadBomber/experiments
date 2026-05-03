---
name: rubyllm-image-generation
description: |
  Generate images from text with RubyLLM. Use this skill for creating images with DALL-E 3, GPT Image 1, Imagen, editing existing images, and working with masks for constrained editing.
---

# RubyLLM Image Generation

Create images from text descriptions using AI models like DALL-E 3 and Imagen.

## Basic Usage

```ruby
# Generate image
image = RubyLLM.paint("A photorealistic red panda coding Ruby")

# Access result
if image.url
  puts "URL: #{image.url}"
  image.save("red_panda.png")  # Save locally
end

if image.base64?
  puts "MIME: #{image.mime_type}"
  File.write("image.png", Base64.decode64(image.data))
end

# Revised prompt (some models optimize your prompt)
puts image.revised_prompt if image.revised_prompt
```

## Models

| Model | Provider | Size | Price/Image |
|-------|----------|------|-------------|
| dall-e-3 | OpenAI | 1024x1024 | $0.040 |
| dall-e-3 | OpenAI | 1024x1792 | $0.080 |
| gpt-image-1 | OpenAI | Various | Supports editing |
| imagen-3 | Google | Various | Base64 output |

```ruby
# DALL-E 3
RubyLLM.paint("Sunset", model: 'dall-e-3')

# GPT Image 1 (supports editing)
RubyLLM.paint("Edit logo", model: 'gpt-image-1', with: 'logo.png')
```

## Image Editing (v1.15+)

Edit existing images:

```ruby
# Basic editing
image = RubyLLM.paint(
  "Turn the logo green",
  model: 'gpt-image-1',
  with: 'logo.png'
)

# Edit with mask (constrain which parts change)
image = RubyLLM.paint(
  "Change background to blue",
  model: 'gpt-image-1',
  with: 'photo.jpg',
  mask: 'mask.png'  # White areas get edited
)
```

## Options

```ruby
# Provider-specific params
chat = RubyLLM.chat.with_params(
  size: '1024x1024',
  quality: 'hd',
  style: 'vivid'
)

image = RubyLLM.paint("Sunset", **chat.params)
```

## Active Storage Integration

```ruby
class GeneratedImage < ApplicationRecord
  has_one_attached :file
end

image = RubyLLM.paint("Sunset")
record = GeneratedImage.create!

if image.base64?
  record.file.attach(
    io: StringIO.open(Base64.decode64(image.data)),
    filename: "sunset.png",
    content_type: image.mime_type
  )
elsif image.url
  # Download and attach
  response = Faraday.get(image.url)
  record.file.attach(
    io: StringIO.new(response.body),
    filename: "sunset.png",
    content_type: response.headers['content-type']
  )
end
```

## Prompt Tips

### Be Specific

```ruby
# Vague
RubyLLM.paint("A dog")

# Specific
RubyLLM.paint("A golden retriever puppy sitting in a sunny meadow, photorealistic, warm lighting")
```

### Style Keywords

```ruby
# Artistic styles
RubyLLM.paint("City skyline, watercolor style, soft pastels")
RubyLLM.paint("Portrait, oil painting, renaissance style")
RubyLLM.paint("Abstract composition, cubist, bold colors")

# Photography styles
RubyLLM.paint("Product photo, studio lighting, white background")
RubyLLM.paint("Landscape, golden hour, dramatic clouds")
```

## See Also

- **Main RubyLLM**: [rubyllm](../SKILL.md)
- **Multi-Modal**: See [rubyllm](../SKILL.md) for using images in chat
