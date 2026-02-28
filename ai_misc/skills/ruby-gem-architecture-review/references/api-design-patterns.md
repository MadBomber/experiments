# API Design Patterns

Public API design patterns drawn from well-known Ruby gems.

## Pattern: Class Macro (Searchkick, Devise, ActsAsParanoid)

Single declarative call configures behavior for a class.

```ruby
# Consumer sees:
class Product < ApplicationRecord
  searchkick word_start: [:name], language: "english"
end

class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable
end
```

**Review criteria:**
- Unknown keyword arguments raise `ArgumentError` immediately
- Options stored as class attribute (not class variable)
- Method defined only once (guard with `unless method_defined?`)
- Works correctly with STI and inheritance

## Pattern: Builder / Fluent (Arel, ActiveRecord::Relation)

Chainable method calls that build up a query or configuration.

```ruby
# Consumer sees:
GemName.new
  .with_timeout(30)
  .using_adapter(:postgresql)
  .where(status: :active)
  .execute
```

**Review criteria:**
- Each method returns `self` (or a new immutable copy)
- Terminal method (`execute`, `to_a`, `result`) is clearly distinct from builders
- Immutable chain (each call returns a new object) preferred over mutating self
- Reasonable defaults — minimal chain should work

## Pattern: Module Function (Benchmark, FileUtils, JSON)

Stateless utility methods available both as module methods and as instance methods.

```ruby
module GemName
  module_function

  def encrypt(data, key:)
    # ...
  end

  def decrypt(data, key:)
    # ...
  end
end

# Used as: GemName.encrypt(data, key: key)
# Or:      include GemName; encrypt(data, key: key)
```

**Review criteria:**
- No hidden state (fully determined by arguments)
- Methods are short and testable in isolation
- `module_function` makes methods both module-level and includable

## Pattern: Wrapping Constructor (Hashie, Money, Pathname)

Custom class that wraps a primitive with domain behavior.

```ruby
# Consumer sees:
price = Money.new(1000, "USD")
price.format  # => "$10.00"
price + Money.new(500, "USD")  # => Money(1500, "USD")

# Or with coercion:
Money(10.00, "USD")
```

**Review criteria:**
- Immutable by default (arithmetic returns new instances)
- Implements expected Ruby protocols (`to_s`, `<=>`, `==`, `hash`, `eql?`)
- Conversion methods to/from primitives (`to_i`, `to_d`, `to_s`)
- Explicit coercion (no implicit type casting surprises)

## Pattern: Null Object (Naught, NullLogger)

Provide a safe no-op implementation for optional dependencies.

```ruby
module GemName
  class NullLogger
    def info(msg) = nil
    def warn(msg) = nil
    def error(msg) = nil
    def debug(msg) = nil
  end

  class << self
    attr_writer :logger

    def logger
      @logger ||= NullLogger.new
    end
  end
end
```

**Review criteria:**
- Null object responds to the same interface as the real object
- Default is the null object (not nil)
- No `if logger` checks scattered through the codebase

## Pattern: Result Object (Dry::Monads, Interactor)

Return success/failure rather than raising exceptions for expected outcomes.

```ruby
module GemName
  class Result
    attr_reader :value, :error

    def self.success(value) = new(value: value)
    def self.failure(error) = new(error: error)

    def success? = @error.nil?
    def failure? = !success?

    private

    def initialize(value: nil, error: nil)
      @value = value
      @error = error
    end
  end
end
```

**Review criteria:**
- Success and failure are distinct (not boolean + value)
- Errors are typed (not bare strings)
- Pattern works with Ruby's case/in for pattern matching

## Keyword Arguments Guidance

```ruby
# Good — clear at call site
def search(query, fields: nil, boost: nil, limit: 20)

# Bad — positional args beyond 2
def search(query, fields, boost, limit, offset, highlight)

# Bad — options hash (unless genuinely open-ended)
def search(query, options = {})

# Acceptable — options hash with KNOWN_KEYWORDS validation
KNOWN_KEYWORDS = %i[fields boost limit offset highlight].freeze

def search(query, **options)
  unknown = options.keys - KNOWN_KEYWORDS
  raise ArgumentError, "unknown keywords: #{unknown.join(', ')}" if unknown.any?
end
```

## Thread Safety Patterns

```ruby
# Safe: frozen constants
DEFAULTS = { timeout: 10, retries: 3 }.freeze

# Safe: class_attribute (Rails) — per-class, inheritable
class_attribute :search_options, default: {}

# Safe: Mutex for mutable shared state
module GemName
  @mutex = Mutex.new

  def self.register(name, handler)
    @mutex.synchronize { @handlers[name] = handler }
  end
end

# Unsafe: mutable class variable
@@config = {}  # Shared across all threads, no synchronization

# Unsafe: mutable module instance variable without mutex
@handlers = {}  # Written from multiple threads
```

## Deprecation Pattern

```ruby
def old_method
  warn "[GemName] old_method is deprecated, use new_method instead. " \
       "It will be removed in v3.0. Called from #{caller_locations(1, 1).first}"
  new_method
end
```
