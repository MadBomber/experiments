# Module Decomposition Patterns

Strategies for breaking large gem classes into maintainable pieces.

## Pattern 1: Include-by-Feature (PgHero / Searchkick)

Split a large class into feature modules, include them all in the main class.

```
lib/gemname/
├── client.rb            # Main class, includes all features
└── methods/
    ├── querying.rb      # Query-related methods
    ├── indexing.rb       # Index management
    ├── configuration.rb # Config-related methods
    └── monitoring.rb    # Health check methods
```

```ruby
module GemName
  class Client
    include Methods::Querying
    include Methods::Indexing
    include Methods::Configuration
    include Methods::Monitoring

    attr_reader :connection

    def initialize(url:)
      @connection = Connection.new(url)
    end
  end
end
```

**When to use:** Single class with many methods (>15) that group naturally by domain.

**Review checklist:**
- [ ] Each module is independently testable
- [ ] Modules don't call private methods from other modules
- [ ] Shared state accessed through the host class interface, not instance variables
- [ ] Module names match the feature they provide

## Pattern 2: Strategy / Adapter (Strong Migrations / Lockbox)

Abstract interface with concrete implementations per backend.

```
lib/gemname/
├── adapters/
│   ├── abstract_adapter.rb
│   ├── postgresql_adapter.rb
│   ├── mysql_adapter.rb
│   └── sqlite_adapter.rb
└── adapter_detection.rb
```

```ruby
module GemName
  module Adapters
    class AbstractAdapter
      def execute(query)
        raise NotImplementedError
      end

      private

      def connection
        raise NotImplementedError
      end
    end
  end
end
```

**When to use:** Gem must support multiple backends, databases, or external services.

**Review checklist:**
- [ ] Abstract base defines the full interface (no methods only in subclasses)
- [ ] Detection logic is centralized (one method picks the adapter)
- [ ] Fallback to abstract adapter for unknown backends (graceful degradation)
- [ ] Each adapter is independently testable with its own fixtures

## Pattern 3: Pipeline / Middleware (Faraday / Rack)

Composable chain of processing steps.

```ruby
module GemName
  class Pipeline
    def initialize
      @steps = []
    end

    def use(step)
      @steps << step
      self
    end

    def call(input)
      @steps.reduce(input) { |data, step| step.call(data) }
    end
  end
end
```

**When to use:** Processing that varies by context, or where consumers need to
inject custom behavior at specific points.

**Review checklist:**
- [ ] Each step has a uniform interface (responds to `call`)
- [ ] Steps are stateless or manage their own state
- [ ] Order of steps is documented and tested
- [ ] Error in one step doesn't corrupt the pipeline

## Pattern 4: Registry (Devise / ActiveModel::Serializer)

Central registry of named components that consumers can extend.

```ruby
module GemName
  class << self
    def strategies
      @strategies ||= {}
    end

    def register(name, klass)
      strategies[name.to_sym] = klass
    end

    def lookup(name)
      strategies.fetch(name.to_sym) do
        raise Error, "Unknown strategy: #{name}. Available: #{strategies.keys.join(', ')}"
      end
    end
  end
end
```

**When to use:** Gem provides a framework where consumers add their own implementations.

**Review checklist:**
- [ ] Registration is explicit (not magic class inheritance hooks)
- [ ] Lookup fails with a helpful error listing available options
- [ ] Registered components have a documented interface contract
- [ ] Thread-safe if registration can happen after boot

## Pattern 5: Concern Extraction (Rails-style)

For gems that extend ActiveRecord or other Rails base classes.

```ruby
module GemName
  module Searchable
    extend ActiveSupport::Concern

    included do
      class_attribute :search_options, default: {}
    end

    class_methods do
      def searchable(**options)
        self.search_options = options
      end

      def search(query)
        # implementation using search_options
      end
    end

    def reindex
      self.class.reindex_record(self)
    end
  end
end
```

**When to use:** Adding behavior to consumer classes via `include` or `extend`.

**Review checklist:**
- [ ] Uses `class_attribute` (not `@@class_variable`) for per-class state
- [ ] Instance methods only access the including class through `self`
- [ ] No assumptions about the including class beyond the documented contract
- [ ] Works with STI / inheritance (class attributes inherit correctly)

## Smell: When Decomposition Goes Wrong

| Smell | Symptom | Fix |
|-------|---------|-----|
| **Circular inclusion** | Module A calls method defined in Module B | Extract shared logic to a third module |
| **Invisible coupling** | Removing one module breaks another | Make dependencies explicit via constructor injection |
| **Feature envy** | Module mostly calls methods on another object | Move the method to that object |
| **Header interfaces** | Abstract base has methods only one subclass overrides | Remove abstract base, use duck typing |
| **Registry bloat** | >20 registered components, most unused | Split into separate gems or use autoload |
