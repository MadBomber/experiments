# PM (PromptManager)

PM (PromptManager) parses YAML metadata from markdown strings or files. It expands shell references, extracts metadata and content, and renders ERB templates on demand.

## Installation

```ruby
require 'pm'
```

## Usage

Given a file `code_review.md`:

```md
---
title: Code Review
provider: openai
model: gpt-4
temperature: 0.3
parameters:
  language: ruby
  code: null
  style_guide: ~/guides/default.md
---
Review the following <%= language %> code using the style guide
at <%= style_guide %>:

<%= code %>
```

Parse it:

```ruby
parsed = PM.parse_file('code_review.md')
parsed.metadata['parameters']
#=> {'language' => 'ruby', 'code' => nil, 'style_guide' => '~/guides/default.md'}
```

Build the prompt with `to_s`:

```ruby
# Provide required params, accept defaults for the rest
parsed.to_s('code' => File.read('app.rb'))

# Override defaults
parsed.to_s('code' => File.read('app.py'), 'language' => 'python')

# All params have defaults — no arguments needed
parsed.to_s

# Missing a required parameter raises an error
parsed.to_s
#=> ArgumentError: Missing required parameters: code
```

Parameters with a `null` default in the YAML are required. Parameters with any other default are optional.

### Shell expansion

`parse_file` expands shell references before parsing:

```md
---
title: Deploy Check
parameters:
  environment: null
---
Current user: $USER
Home directory: ${HOME}
Date: $(date +%Y-%m-%d)
Git branch: $(git rev-parse --abbrev-ref HEAD)
Deploy to: <%= environment %>
```

- `$ENVAR` and `${ENVAR}` are replaced with the environment variable's value.
- `$(command)` is executed and replaced with its stdout.
- Missing environment variables are replaced with an empty string.
- Failed commands raise an error.

Shell expansion is also available directly:

```ruby
PM.expand_shell(string)
```

### Parsing a string

```ruby
parsed = PM.parse(string)
```

`parse` extracts metadata and content only. It does not perform shell expansion.

## Processing pipeline

1. Shell expansion (`$ENVAR`, `$(command)`)
2. Extract YAML metadata and markdown content
3. ERB rendering on demand via `to_s`

## LICENSE

Copyright (c) 2013 Marc Busqué - <marc@lamarciana.com>

This project is licensed under the MIT License - see the [LICENSE](LICENSE.txt) file for details.
