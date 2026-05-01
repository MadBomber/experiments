# First Principles for Software Development

A guide for AI coding agents to produce high-quality, maintainable software.

---

## Core Philosophy

Write code that is **simple**, **clear**, and **purposeful**. Every line should earn its place. Prefer the obvious solution over the clever one. Code is read far more often than it is written—optimize for the reader.

---

## 1. DRY — Don't Repeat Yourself

> "Every piece of knowledge must have a single, unambiguous, authoritative representation within a system."

### Guidelines

- Extract repeated logic into methods, modules, or classes
- Use constants for magic numbers and strings
- Create shared abstractions when patterns emerge naturally
- Avoid copy-paste programming

### Caveats

- Duplication is cheaper than the wrong abstraction
- Two occurrences may be coincidental; wait for three before abstracting
- Some duplication across boundaries (services, modules) is acceptable for decoupling

---

## 2. KISS — Keep It Simple, Stupid

> "Simplicity is the ultimate sophistication."

### Guidelines

- Solve the problem at hand, not hypothetical future problems
- Prefer straightforward solutions over clever ones
- Reduce moving parts: fewer dependencies, fewer layers, fewer abstractions
- If you can delete code and maintain functionality, delete it
- Avoid premature optimization

### Questions to Ask

- Can this be simpler?
- What can I remove?
- Will someone unfamiliar understand this in six months?

---

## 3. SOLID Principles

### Single Responsibility Principle (SRP)

A class or module should have one reason to change.

- Each class handles one concept
- Methods do one thing
- If you struggle to name it, it may do too much

### Open/Closed Principle (OCP)

Open for extension, closed for modification.

- Add new behavior through new code, not by changing existing code
- Use inheritance, composition, or callbacks to extend functionality
- Design interfaces that anticipate variation

### Liskov Substitution Principle (LSP)

Subtypes must be substitutable for their base types.

- Subclasses should not break expectations set by parent classes
- Honor the contract of the interface or base class
- Avoid type-checking to determine behavior

### Interface Segregation Principle (ISP)

No client should depend on methods it does not use.

- Prefer small, focused interfaces over large, general ones
- Split fat interfaces into cohesive groups
- Depend on what you need, nothing more

### Dependency Inversion Principle (DIP)

Depend on abstractions, not concretions.

- High-level modules should not depend on low-level modules
- Inject dependencies rather than instantiating them internally
- Program to interfaces, not implementations

---

## 4. YAGNI — You Aren't Gonna Need It

> "Always implement things when you actually need them, never when you just foresee that you need them."

### Guidelines

- Build only what is required now
- Resist adding features "just in case"
- Delete dead code and unused functionality
- Avoid speculative generality

### Signs of YAGNI Violations

- Configuration options no one uses
- Abstract factories for single implementations
- "Framework" code for one use case
- Comments like "might need this later"

---

## 5. PoLA — Principle of Least Astonishment

> "If a feature has a high astonishment factor, it may be necessary to redesign it."

### Guidelines

- Methods should do what their names suggest
- Side effects should be obvious or absent
- Follow language and framework conventions
- Consistent behavior across similar interfaces
- Error messages should be helpful and accurate

### Application

- A method named `get_user` should not modify state
- A method named `save!` should indicate it may raise exceptions
- Boolean methods should return only true or false
- Destructive methods should be clearly marked (e.g., `delete!`, `clear!`)

---

## 6. Unix Philosophy

> "Write programs that do one thing and do it well."

### Core Tenets

1. **Do one thing well** — Small, focused tools over monolithic systems
2. **Compose programs** — Design outputs to become inputs for other programs
3. **Text streams** — Use simple, portable data formats
4. **Prototype early** — Get it working, then refine
5. **Portability over efficiency** — Prefer solutions that work across environments
6. **Avoid captive interfaces** — Don't trap users in interactive modes
7. **Make programs filters** — Transform data without unnecessary state

### Guidelines

- Write small, composable functions and classes
- Prefer clear text-based interfaces and configurations
- Build pipelines of simple operations
- Fail early and explicitly with meaningful errors
- Use standard formats (JSON, YAML, CSV) for data exchange

---

## 7. Strunk & White for Code

Adapted from "The Elements of Style" for software development.

### Omit Needless Code

- Every line should serve a purpose
- Remove comments that restate the obvious
- Delete dead code, commented-out blocks, and unused variables
- Prefer built-in functionality over custom implementations

### Be Clear

- Use descriptive, unambiguous names
- Prefer explicit over implicit behavior
- Structure code to reveal intent
- Write self-documenting code; add comments only for "why," not "what"

### Be Concise

- Shorter is better when clarity is maintained
- Avoid redundant expressions (`if condition == true`)
- Consolidate related operations
- Use idiomatic patterns of the language

### Be Consistent

- Follow established conventions within the codebase
- Use consistent naming schemes
- Apply uniform formatting throughout
- Pattern your code after existing code in the project

### Revise and Rewrite

- First drafts are rarely optimal
- Refactor as understanding improves
- Simplify when revisiting code
- Code review as an editing process

---

## 8. Rails Doctrine

### Convention Over Configuration

- Follow established patterns unless there is a compelling reason not to
- Sensible defaults reduce decisions and errors
- New team members can navigate convention-based code
- Deviate only when the convention is genuinely inappropriate

### Programmer Happiness

- Optimize for developer experience
- Clear, readable code over terse cleverness
- Tools should reduce friction, not add it
- Beautiful code is more maintainable

### The Menu is Omakase

- Trust the framework's curated choices
- Resist the urge to customize everything
- Accept constraints as guides, not limitations
- Go with the grain of your tools

### Value Integrated Systems

- Prefer full-stack solutions over piecemeal assembly
- Coherent systems over best-of-breed components
- Reduced integration overhead frees time for features

### Progress Over Stability

- Embrace evolution and improvement
- Update dependencies regularly
- Deprecate gracefully but decisively
- Old patterns can give way to better ones

### Push Up a Big Tent

- Welcome diverse solutions within the ecosystem
- Multiple valid approaches can coexist
- Avoid dogmatism; context determines best practice

---

## Synthesis: Guiding Heuristics

When writing code, apply these principles as a hierarchy:

1. **Make it work** — Solve the problem correctly
2. **Make it clear** — Others (and future you) can understand it
3. **Make it simple** — Remove unnecessary complexity
4. **Make it right** — Follow conventions and principles
5. **Make it fast** — Optimize only when measured and necessary

### Decision Framework

| Situation | Apply |
|-----------|-------|
| Repeated code | DRY (but wait for 3 occurrences) |
| Complex solution | KISS — find a simpler way |
| Large class/module | SOLID — break it apart |
| Speculative feature | YAGNI — remove it |
| Surprising behavior | PoLA — make it predictable |
| Monolithic design | Unix — compose small parts |
| Verbose or unclear | Strunk & White — edit ruthlessly |
| Configuration sprawl | Rails — embrace convention |

---

## Anti-Patterns to Avoid

- **Premature abstraction** — Abstracting before patterns emerge
- **Gold plating** — Adding unrequested features or polish
- **Cargo culting** — Copying patterns without understanding them
- **Over-engineering** — Building for imaginary scale or flexibility
- **Magic** — Behavior that is non-obvious or hidden
- **Shotgun surgery** — Changes requiring edits across many files
- **God objects** — Classes that know or do too much
- **Stringly typed** — Using strings where structured types belong

---

## Final Mandate

> Write the simplest code that could possibly work. Then verify it works. Then ask: can it be simpler?

Code is a liability. Every line is a potential bug, a maintenance burden, a cognitive load. The best code is no code. The second best is the least code that solves the problem clearly and correctly.

---

*These principles are guidelines, not laws. Context matters. Use judgment. When principles conflict, prefer the solution that best serves the user and the long-term health of the codebase.*
