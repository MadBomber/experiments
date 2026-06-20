---
name: solid-ruby
description: >
  Apply SOLID as design judgment for Ruby, not as a mechanical rulebook.
  Use this skill when deciding WHETHER a SOLID refactor is warranted, when a
  class "feels wrong" but you're not sure splitting helps, when reviewing code
  for over-application (anemic models, service-object sludge, concern drawers,
  over-injection), or when reasoning about how Ruby's open classes, duck typing,
  and protocols change what each principle actually buys you. Complements the
  solid-principles skill, which covers detection heuristics and refactoring
  mechanics.
---

# SOLID as Judgment for Ruby

SOLID was phrased for statically typed, compiled OO languages (Java, C#). Ruby
removes several constraints that made the original wording feel necessary:

- Classes are open; method tables are mutable and reopenable anywhere.
- Existing methods can be replaced at runtime (monkey-patching).
- Duck typing matters more than nominal class hierarchies.
- There are no formal interfaces — protocols are informal.
- Tests can replace behavior without a dependency-injection container.

So the useful question in Ruby is **not** "does this code follow SOLID?" It is
**"what does this principle still help me notice?"** In Ruby, SOLID works better
as a set of prompts than as a rulebook. It names the trade-offs you are already
making.

> This skill is the judgment layer. For detection checklists, violation patterns,
> and concrete refactoring recipes, use the companion **solid-principles** skill.
> Reach for *this* skill when the question is *whether* to act, not *how*.

## When to Use

- A class "feels wrong" but you're unsure whether splitting it actually helps.
- A reviewer flagged a SOLID "violation" and you suspect the cure is worse.
- You're tempted to extract a service object, inject a dependency, or split a
  module — and want to pressure-test the impulse first.
- You're auditing a Rails codebase for *over*-application of SOLID.
- You want to reason from Ruby's actual semantics, not Java-shaped intuitions.

## The Core Move (apply to every principle)

```
principle as originally stated
        ↓
does it apply literally to Ruby?
        ↓
not quite — Ruby removed a constraint
        ↓
what is still useful here?
```

Run this before any SOLID-motivated refactor. If you can't answer the last line
with a concrete benefit ("this makes test X deterministic," "this makes change Y
additive"), you are likely about to scatter complexity rather than reduce it.

---

## S — Single Responsibility → Cohesion and Volatility

**Literal rule:** "A class should have only one reason to change."
**Why it's slippery in Ruby:** "reason to change" depends entirely on the
abstraction level you pick. `String` has a dozen plausible responsibilities
(text, bytes, encoding, formatting, matching, slicing, mutation, conversion…)
and is still an excellent abstraction because they orbit *one concept*.

Hold these apart:

```
single purpose   != tiny class
single responsibility != one method
many methods      != many responsibilities
```

A class can be large and cohesive. A class can be small and badly designed.

**Don't ask** "does this class do more than one thing?" (most useful classes do).
**Ask instead:**

- Do these behaviors *belong together* conceptually?
- Do they *change together*?
- Are callers forced to depend on behavior they don't care about?
- Is the class hiding a useful abstraction, or just accumulating chores?
- Would splitting *reduce* complexity, or merely *scatter* it?

**SRP earns its keep** when a class becomes a coordination point for *unrelated
volatility* — e.g. an `Invoice` that calculates totals (tax rules) *and* renders
PDFs (design) *and* charges cards (payment provider) *and* syncs to Salesforce
(external API) *and* sends email (templates). Five unrelated reasons to change.

### The Ruby/Rails over-application trap

SRP usually arrives *late*, after a model is already a junk drawer:

```ruby
class User < ApplicationRecord
  # auth, billing, permissions, onboarding,
  # notification prefs, analytics, third-party sync, admin reporting
end
```

The reflex is "extract service objects." Sometimes that helps. Sometimes it
produces a *worse* system: an anemic model orbited by procedural
`UserSignupService`, `UserBillingService`, `UserNotifier`, `UserPolicyUpdater`,
`UserLifecycleManager` — no domain clarity, just chores in new costumes.

**Better framing:** keep classes centered on a strong concept. Split when
*volatility*, *dependency pressure*, or a *muddy purpose* makes the class harder
to understand — not because it crossed a line count.

---

## O — Open/Closed → Make Modification Unnecessary

**Literal rule:** "Open for extension, closed for modification."
**Why it barely applies in Ruby:** unless frozen, every class is open for *both*.
Method tables are mutable; even defensive hooks can be removed:

```ruby
class String
  def upcase = "nope"     # existing behavior, replaced at runtime
end

OpenClosed.singleton_class.remove_method(:method_added)  # the defense is removable too
```

Ruby's only real closure is `freeze`:

```
unfrozen class => open for extension AND modification
frozen class    => closed for extension AND modification
```

There is no language-enforced "open for extension, closed for modification"
state. So OCP in Ruby is a **design preference, not a guarantee**:

> Design so that *expected* changes are made by **adding** new objects
> (strategies, handlers, adapters, policies, serializers) or configuration —
> not by editing a fragile central conditional.

Adding a notification channel should mean "write a delivery object and register
it," not "add a `when :slack` to the `case`." Ruby won't *stop* anyone from
monkey-patching your class later; OCP here rests on convention, tests, gem
boundaries, frozen constants, and API design — not the compiler.

> The mechanics (registry/strategy pattern, `inherited` auto-registration) live
> in the **solid-principles** skill. Ruby-specific closure tool worth knowing:
> **`Data.define`** and frozen value objects give you genuinely
> closed-for-modification value types (e.g. `Money`).

**Phrase it as:** in Ruby, OCP isn't about making classes impossible to modify.
It's about making modification *unnecessary* for the changes you expect.

---

## L — Liskov Substitution → Honor the Protocol's Contract

This is the most Ruby-revealing principle. Ruby programmers rarely program
against nominal class hierarchies in the first place — they program against
**protocols** (duck typing). LSP isn't useless; its *framing* shifts.

**Don't ask** "does the subclass behave differently?" (a subtype is useful
precisely *because* it changes behavior — LSP is about invariants, not identity).
**Ask:** "does it violate an assumption callers reasonably rely on?" — explicit,
implicit, documented, tested, or conventional.

In Ruby those assumptions are **protocols**, not static types:

```ruby
def write_report(io)
  io.write("report")   # File, StringIO, socket, logger, test double — all fine
end
```

> If an object claims to participate in a protocol, callers expect it to honor
> that protocol's *behavioral* expectations — not just its method names.

An object that `respond_to?(:each)` but yields metadata sometimes, DB rows other
times, and a string depending on internal state technically "responds to each"
but is a poor `Enumerable` participant. That's the LSP violation.

### Identity checks are hostile to substitution

```ruby
value.instance_of?(String)   # exactly String — rejects every compatible subtype
value.is_a?(String)          # String or subclass/module ancestor
value.respond_to?(:to_s)     # method presence (shallow — not behavior)
```

`instance_of?` says "I only accept this exact concrete class," which kills
substitutability. Prefer capability and state questions, which is exactly why
idiomatic Rails reaches for `record.persisted?`, `policy.allowed?`,
`object.to_param`, `relation.to_a`, `response.success?`, and `to_partial_path`
(participate in partial rendering with no base class) over class checks.

**Guideline:**
- Prefer: "Can this object do what I need?"
- Avoid: "Is this object exactly this class?"
- Subclass only when the child preserves the parent's *meaningful* contract;
  otherwise use composition or delegation.

---

## I — Interface Segregation → Cohesive API Surface, Not Tiny Modules

**Literal rule:** "Clients shouldn't depend on methods they don't use."
**Why it's weaker in Ruby:** an object never has to *declare* an interface before
use — a caller just sends the message it needs. An uncalled method on a 200-method
object imposes *no runtime dependency*. So the literal ISP problem mostly evaporates.

The pressure moves from **type dependency** to **API surface area / cognitive
cost**. A huge interface still forces a programmer to ask which methods matter,
which belong together, which are safe to override, which interact surprisingly.

> A large public surface works *fine* when the methods form a cohesive API.

That's why `String`, `Array`, `Hash`, `ActiveRecord::Relation` get away with huge
APIs — the methods orbit a strong concept. **Size isn't the problem;
*conceptual leakage* is.** A `User` exposing `full_name`, `charge_subscription!`,
`sync_to_crm!`, `export_to_csv`, `generate_avatar`, `send_weekly_digest` is
suspicious because the methods serve *different audiences and change for different
reasons* — not because there are many of them.

### The concern-drawer trap (Rails-specific)

```ruby
class User < ApplicationRecord
  include User::Authentication
  include User::Billing
  include User::Notifications
  include User::Analytics
  include User::Search
end
```

Sometimes meaningful decomposition. Sometimes just a "concern drawer": the class
is *still* conceptually huge, now smeared across files. Concerns can reduce file
length without reducing design complexity — and force the reader to reconstruct
the object by chasing modules.

**Split for real usage boundaries** — core vs optional plugin behavior, read vs
write, formatting vs transport, admin vs public API, expensive integrations vs
local behavior. **Don't split** because: the file is long, RuboCop flags module
length, "every class should be small," or "SOLID says so." Those produce
mechanical decomposition, not better design.

> Read ISP in Ruby as: keep public APIs cohesive, and separate optional protocol
> families only when they're genuinely consumed independently.

---

## D — Dependency Inversion → Control Variability, Demand-Driven

**Literal rule:** "High-level policy shouldn't depend on low-level detail; both
depend on abstractions." In Ruby the "abstraction" is usually just a **protocol**
(`schedule.work_hours_for(date)`) — no formal interface object required. So DIP
becomes: **decide where concrete choices are made, and don't bury hard-to-control
ones inside objects when they need to vary.**

### The central law

> Abstractions are not intrinsically useful. They are useful only to the extent
> that they make *other* code simpler.

Apply DIP **demand-driven, not ideology-driven.** "Concrete = bad, interface =
good, factory = better, container = enterprise-grade" produces code that is
theoretically flexible and practically harder to read.

### Which dependencies are worth isolating?

Fine to construct internally (cheap, deterministic, local):

```ruby
@items = []
@cache = {}
@formatter = DefaultFormatter.new
```

Suspect — hard to test, slow, global, stateful, time/network/env-dependent:

```ruby
@client = ExternalApi::Client.new
@date   = Date.today
@uuid   = SecureRandom.uuid
@logger = Rails.logger
```

### The injection ladder (pick the lowest rung that solves the real problem)

Walk *up* only when a concrete need forces you. Each rung adds public API surface
and shifts responsibility outward to callers.

| Rung | Form | Use when | Cost |
|---|---|---|---|
| 1. Hard-code | `@date = Date.today` | trivial class, rarely tested in isolation | nondeterministic tests |
| 2. Inject the value | `def initialize(date: Date.today)` | **usually the best first move** — removes the volatile bit | almost none |
| 3. Inject the *class* | `def initialize(date: Date.today, schedule_class: MonthlySchedule)` | you must vary the implementation **and** preserve construction invariants | one more ctor param |
| 4. Inject the *object* | `def initialize(schedule:, date: Date.today)` | construction genuinely belongs outside, or caller already holds one | **breaks invariants** — caller can pass a Dec date with a Jan schedule |
| 5. Formal abstraction / container | factories, clocks, policies injected | library/framework/plugin code, or many interchangeable impls | design inflation if premature |

The instructive failure is **rung 4**: injecting the fully-built collaborator
hands every caller responsibility for an invariant the class used to protect.
You gained flexibility and *lost* a guarantee. Rung 3 keeps the class in control
of *how* the collaborator is built while still allowing a fake in tests.

### Rails reality

Active Record *deliberately* combines domain behavior and data access. Importing
repository / hexagonal habits wholesale ("inject `UserRepository`,
`InvoiceRepository`, `PaymentGateway`, `Mailer`, `Clock`, `IdGenerator`…") is
often needless ceremony — Rails already gives stable abstractions (`User.find`,
`Invoice.create!`, `InvoiceMailer.with(...).deliver_later`, `Time.current`).

Inject only **volatile boundaries**:

```ruby
class CreateInvoice
  def initialize(payment_gateway: StripeGateway.new)
    @payment_gateway = payment_gateway   # the one thing that's external + worth faking
  end
end
```

For time-dependence, prefer Rails' time helpers
(`travel_to` / `Time.current` / `ActiveSupport::Testing::TimeHelpers`) over
introducing a `clock:` dependency too early.

> The Ruby DIP rule: depend on protocols where variation is *real*, inject where
> control is *needed*, and avoid abstractions that make the caller responsible
> for complexity the object can safely own.

---

## The One-Page Restraint Checklist

Before any SOLID-motivated refactor, confirm at least one is true:

- [ ] **Volatility:** these behaviors change for genuinely different reasons.
- [ ] **Determinism:** isolating this makes a flaky/slow/global test deterministic.
- [ ] **Additivity:** the expected change becomes "add an object," not "edit a conditional."
- [ ] **Cohesion:** the split reflects a real usage boundary, not a line count.
- [ ] **Invariant safety:** the change doesn't export an invariant to every caller.

If none hold, you are probably **scattering** complexity, not reducing it. Stop.

### Smells of over-application (the failure mode this skill guards against)

- Anemic model + a constellation of procedural `*Service` objects.
- Concern drawers: file count up, conceptual complexity unchanged.
- Constructors with 5+ injected collaborators in an ordinary Rails app.
- Injected fully-built objects that let callers create invalid combinations.
- Factories/containers/clocks in code with exactly one implementation.
- `instance_of?` / exact class checks where a capability question would do.

---

## The Broader Lesson

Across all five, the same move repeats: the original principle points at
something real, but the literal wording is too blunt for Ruby.

- **SRP** → cohesion and volatility, not tiny classes.
- **OCP** → make expected change additive, not classes unmodifiable.
- **LSP** → honor behavioral contracts via protocols, not inheritance trees.
- **ISP** → cohesive public APIs, not mechanically split modules.
- **DIP** → control the dependencies that vary, not inject everything.

SOLID is worth understanding in Ruby not because it tells you how many objects to
create, but because it gives **names to the trade-offs you're already making.**

---

*Sources: Jeremy Evans, "SOLID" chapter in* Polished Ruby Programming*; Syed
Aslam, "What SOLID Still Teaches Ruby Programmers"
(syedaslam.com). This skill is the judgment companion to **solid-principles**,
which provides detection heuristics, violation patterns, and refactoring recipes.*
