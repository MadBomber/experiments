# Aicommit

## Overview

**Aicommit** is a Ruby gem designed to generate high-quality commit messages for git diffs. It leverages AI to analyze changes in your codebase and create concise, meaningful commit messages following best practices.

## Features

- Automatically generate commit messages based on code diffs.
- Follow a configurable style guide for commit messages.
- Integration with AI models for enhanced message generation.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aicommit'
```

And then execute:

```shell
bundle install
```

Or install it yourself as:

```shell
gem install aicommit
```

## Usage

To generate a commit message:

```shell
aicommit -m MODEL -c CONTEXT
```

- `-m, --model=MODEL`: Specify the AI model to use.
- `-c, --context=CONTEXT`: Extra context to be considered.

### Options

- `-a, --amend`: Amend the last commit.
- `-d, --dry`: Dry run the command without making any changes.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

1. Fork it (<https://github.com/your_username/aicommit/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open-source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
