---
name: solid-principles
description: >
  Apply SOLID principles when writing, reviewing, or refactoring Ruby code.
  This skill should be used when designing classes, evaluating architecture,
  reviewing pull requests, or refactoring existing code. It provides
  actionable checklists, violation detection patterns, and Ruby-idiomatic
  refactoring strategies for each of the five SOLID principles.
---

# SOLID Principles for Ruby

Apply the five SOLID principles as practical tools for writing, reviewing,
and refactoring Ruby code. Each principle includes detection heuristics,
Ruby-idiomatic solutions, and concrete examples.

## When to Use

- Designing new classes or modules
- Reviewing code for architectural quality
- Refactoring classes that have grown unwieldy
- Evaluating whether a dependency can be swapped safely
- Deciding where to place new behavior in an existing codebase

## The Five Principles — Quick Reference

| Principle | One-line rule | Violation smell |
|---|---|---|
| **S** — Single Responsibility | A class has only one reason to change | Class name needs "And" or "Manager" |
| **O** — Open/Closed | Extend behavior without modifying existing code | Case statements that grow with new types |
| **L** — Liskov Substitution | Subclasses substitute for their parent without surprises | Subclass raises `NotImplementedError` or changes return type |
| **I** — Interface Segregation | Depend only on methods you actually call | Including a module but using 2 of its 15 methods |
| **D** — Dependency Inversion | Depend on abstractions, not concretions | Hard-coded class names inside methods |

---

## S — Single Responsibility Principle

**Rule:** A class should have only one reason to change.

### Detection Heuristics

- [ ] Class name contains "And", "Or", "Manager", "Handler", "Processor", "Utils"
- [ ] Class has methods that fall into distinct groups (e.g., persistence + formatting + notification)
- [ ] Class file exceeds 150 lines
- [ ] Class has more than 5 public methods serving different concerns
- [ ] Changing one feature requires modifying unrelated methods in the same class
- [ ] The class description requires the word "and"

### Ruby Violation Patterns

```ruby
# VIOLATION: Order handles persistence, formatting, AND notification
class Order
  def save
    DB.insert(to_hash)
  end

  def to_pdf
    PDFGenerator.new(self).render
  end

  def send_confirmation
    Mailer.deliver(confirmation_email)
  end
end
```

### Refactoring Strategy

Extract each responsibility into its own object:

```ruby
# Each class has one reason to change
class Order
  attr_reader :items, :total
  # Domain logic only: what IS an order?
end

class OrderRepository
  def save(order) = DB.insert(order.to_hash)
end

class OrderPresenter
  def initialize(order) = @order = order
  def to_pdf = PDFGenerator.new(@order).render
end

class OrderNotifier
  def initialize(order) = @order = order
  def send_confirmation = Mailer.deliver(confirmation_email)
end
```

### When to Bend This Rule

Single responsibility does not mean single method. A class that groups
closely related behavior is fine. `User` having `full_name`, `email_domain`,
and `active?` is one responsibility: representing a user.

---

## O — Open/Closed Principle

**Rule:** Open for extension, closed for modification.

### Detection Heuristics

- [ ] Adding a new type requires modifying an existing `case`/`if-elsif` chain
- [ ] Method contains conditional logic based on the type or class of an argument
- [ ] New features require editing existing, tested code
- [ ] You find yourself adding `when :new_thing` to growing switch statements

### Ruby Violation Patterns

```ruby
# VIOLATION: Adding a new format requires modifying this method
def export(format)
  case format
  when :csv  then export_csv
  when :json then export_json
  when :xml  then export_xml
  # Adding :pdf means editing this method
  end
end
```

### Refactoring Strategy

Use polymorphism, a registry, or Ruby's duck typing:

```ruby
# Strategy pattern with registry
module Exporters
  REGISTRY = {}

  def self.register(format, klass)
    REGISTRY[format] = klass
  end

  def self.for(format)
    REGISTRY.fetch(format) { raise ArgumentError, "Unknown format: #{format}" }
  end
end

class CsvExporter
  def export(data) = # ...
end

Exporters.register(:csv, CsvExporter)

# Adding :pdf requires only a new class + registration — no existing code changes
def export(format)
  Exporters.for(format).new.export(data)
end
```

Ruby-idiomatic alternatives:
- **Inheritance** with `def self.inherited` hook for auto-registration
- **Module inclusion** with `def self.included` callback
- **Convention-based lookup:** `"Exporters::#{format.to_s.classify}".constantize`

---

## L — Liskov Substitution Principle

**Rule:** Objects of a subclass must be substitutable for objects of their
superclass without altering correctness. A dependency can be swapped out
so long as the actual and expected contracts are met — the new dependency
requires NO MORE and promises NO LESS.

### Detection Heuristics

- [ ] Subclass raises `NotImplementedError` for an inherited method
- [ ] Subclass changes the return type of an inherited method
- [ ] Subclass adds preconditions the parent didn't require
- [ ] Subclass silently ignores arguments the parent used
- [ ] Client code checks `is_a?` or `class` to decide behavior
- [ ] Substituting a subclass breaks tests written against the parent

### Ruby Violation Patterns

```ruby
# VIOLATION: Square breaks Rectangle's contract
class Rectangle
  attr_accessor :width, :height

  def area = width * height
end

class Square < Rectangle
  def width=(val)
    @width = val
    @height = val  # Surprise! Setting width changes height
  end
end

# Client code breaks:
def stretch(rect)
  rect.width = 10
  rect.height = 5
  rect.area  # expects 50, Square returns 100
end
```

### Duck Typing and LSP

Ruby's duck typing is a powerful LSP tool. Informal contracts between
a client and a dependency mean any object that quacks correctly can
be swapped in:

```ruby
# Client depends on the contract: responds to #call with (message)
# and returns a truthy/falsy delivery status
class NotificationSender
  def initialize(transport:)
    @transport = transport
  end

  def send(message)
    @transport.call(message)
  end
end

# All of these satisfy the contract:
EmailTransport  = ->(msg) { Mailer.deliver(msg) }
SmsTransport    = ->(msg) { TwilioClient.send(msg) }
SlackTransport  = ->(msg) { SlackWebhook.post(msg) }
NullTransport   = ->(_msg) { true }  # For testing

# LSP satisfied: any transport substitutes without surprises
```

### Verification Approach

Write tests against the interface, not the implementation. If a test
suite passes with any conforming object, LSP is satisfied:

```ruby
# Shared examples enforce the contract
RSpec.shared_examples "a transport" do
  it "responds to #call" do
    expect(subject).to respond_to(:call)
  end

  it "accepts a message argument" do
    expect { subject.call("test") }.not_to raise_error
  end
end
```

---

## I — Interface Segregation Principle

**Rule:** Depend only on the methods you actually use. Prefer small,
focused interfaces over large, general-purpose ones.

### Detection Heuristics

- [ ] Module has >10 methods but most includers use only 2-3
- [ ] Including a module forces implementing methods the includer doesn't need
- [ ] A dependency exposes 20 methods but the client calls 2
- [ ] Test setup requires stubbing methods the test never exercises

### Ruby Violation Patterns

```ruby
# VIOLATION: Reportable is a grab-bag of unrelated methods
module Reportable
  def to_csv = # ...
  def to_pdf = # ...
  def to_json = # ...
  def to_xml = # ...
  def email_report = # ...
  def schedule_report = # ...
  def archive_report = # ...
end

# Invoice only needs CSV and PDF but gets everything
class Invoice
  include Reportable
end
```

### Refactoring Strategy

Split into focused modules:

```ruby
module CsvExportable
  def to_csv = # ...
end

module PdfExportable
  def to_pdf = # ...
end

module Schedulable
  def schedule = # ...
  def archive = # ...
end

class Invoice
  include CsvExportable
  include PdfExportable
  # Only what Invoice actually needs
end
```

### Ruby-Specific Guidance

Ruby doesn't have formal interfaces, but the principle still applies:
- **Modules** are Ruby's interfaces — keep them cohesive
- **Duck typing** naturally supports ISP — depend on the method, not the class
- **Forwardable** lets you expose only specific methods from a delegate:

```ruby
class Dashboard
  extend Forwardable

  def_delegators :@report, :total_revenue, :user_count
  # Only delegates what Dashboard needs, not all of Report
end
```

---

## D — Dependency Inversion Principle

**Rule:** High-level modules should not depend on low-level modules.
Both should depend on abstractions.

### Detection Heuristics

- [ ] Class instantiates its own collaborators with hard-coded class names
- [ ] Changing a low-level detail (database, API client) requires editing high-level logic
- [ ] Unit testing requires loading the real dependency (can't substitute a fake)
- [ ] Method contains `SomeSpecificClass.new` rather than receiving a collaborator

### Ruby Violation Patterns

```ruby
# VIOLATION: OrderProcessor is welded to Stripe and Postgres
class OrderProcessor
  def process(order)
    payment = Stripe::Charge.create(amount: order.total)
    ActiveRecord::Base.connection.execute("INSERT INTO orders ...")
    SendGridMailer.deliver(order.confirmation_email)
  end
end
```

### Refactoring Strategy

Inject dependencies — let the caller decide which implementations to use:

```ruby
class OrderProcessor
  def initialize(payment_gateway:, repository:, notifier:)
    @payment_gateway = payment_gateway
    @repository = repository
    @notifier = notifier
  end

  def process(order)
    @payment_gateway.charge(order.total)
    @repository.save(order)
    @notifier.confirm(order)
  end
end

# Production wiring
OrderProcessor.new(
  payment_gateway: StripeGateway.new,
  repository: PostgresOrderRepository.new,
  notifier: EmailNotifier.new
)

# Test wiring
OrderProcessor.new(
  payment_gateway: FakeGateway.new,
  repository: InMemoryRepository.new,
  notifier: NullNotifier.new
)
```

### Ruby Injection Patterns

```ruby
# 1. Constructor injection (preferred for required deps)
def initialize(logger: Logger.new($stdout))
  @logger = logger
end

# 2. Default with override (good for optional deps)
def initialize(client: nil)
  @client = client || DefaultClient.new
end

# 3. Module-level default (Andrew Kane pattern)
module GemName
  class << self
    attr_writer :client

    def client
      @client ||= DefaultClient.new
    end
  end
end

# 4. Block injection (for one-off customization)
def process(&on_error)
  rescue StandardError => e
    on_error ? on_error.call(e) : raise
  end
end
```

---

## Applying SOLID During Code Review

When reviewing code, work through this checklist:

### Quick Scan (30 seconds per class)

1. **S:** Can you describe what this class does without using "and"?
2. **O:** Would adding a new variant require editing this class?
3. **L:** If this class has subclasses, can they substitute without surprises?
4. **I:** Does this class depend on interfaces where it uses all the methods?
5. **D:** Does this class create its own collaborators, or receive them?

### Deeper Review (when violations are found)

1. Identify the specific violation and its impact on testability and changeability
2. Check whether the violation is pragmatic (acceptable complexity trade-off)
   or structural (will cause pain as the codebase grows)
3. Propose the minimal refactoring that resolves the violation
4. Verify the refactoring doesn't introduce a different SOLID violation

### When to Accept a Violation

SOLID principles are guidelines, not laws. Accept violations when:
- The class is genuinely simple and unlikely to change
- The alternative introduces more complexity than the violation
- The code is a script or one-off tool, not a library
- Performance requires a pragmatic compromise

For detailed Ruby examples and edge cases, see:
- **[references/ruby-solid-examples.md](references/ruby-solid-examples.md)** — Extended examples from real-world Ruby gems
- **[references/solid-testing-strategies.md](references/solid-testing-strategies.md)** — Testing patterns that reinforce SOLID
