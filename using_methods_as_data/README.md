# Methods as Data - Ruby Metaprogramming Experiments

This directory explores treating Ruby methods as first-class objects, progressing from basic concepts to rule-based inference systems.

## Overview

The experiments demonstrate how Ruby's metaprogramming capabilities allow methods to be stored, introspected, and invoked dynamically. This enables powerful patterns like rule engines and inference systems.

## Architecture

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 500" style="background-color: transparent;">
  <defs>
    <style>
      .title { fill: #00ff88; font-family: monospace; font-size: 18px; font-weight: bold; }
      .box { fill: #1a1a2e; stroke: #00ff88; stroke-width: 2; rx: 5; }
      .box-advanced { fill: #1a1a2e; stroke: #ff6b6b; stroke-width: 2; rx: 5; }
      .text { fill: #e0e0e0; font-family: monospace; font-size: 14px; }
      .label { fill: #888; font-family: monospace; font-size: 12px; font-style: italic; }
      .arrow { stroke: #00ff88; stroke-width: 2; fill: none; marker-end: url(#arrowhead); }
    </style>
    <marker id="arrowhead" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto">
      <polygon points="0 0, 10 3, 0 6" fill="#00ff88" />
    </marker>
  </defs>

  <text x="400" y="30" text-anchor="middle" class="title">Methods as Data - Progression</text>

  <!-- Level 1: Basic -->
  <rect x="50" y="60" width="200" height="80" class="box"/>
  <text x="150" y="90" text-anchor="middle" class="text">test.rb</text>
  <text x="150" y="110" text-anchor="middle" class="label">Basic method storage</text>
  <text x="150" y="125" text-anchor="middle" class="label">&amp; invocation</text>

  <!-- Level 2: Introspection -->
  <rect x="300" y="60" width="200" height="80" class="box"/>
  <text x="400" y="90" text-anchor="middle" class="text">get_optional_defaults.rb</text>
  <text x="400" y="110" text-anchor="middle" class="label">AST introspection</text>
  <text x="400" y="125" text-anchor="middle" class="label">Parameter extraction</text>

  <!-- Level 3: Rule Systems -->
  <rect x="550" y="60" width="200" height="80" class="box-advanced"/>
  <text x="650" y="90" text-anchor="middle" class="text">rule_based_system.rb</text>
  <text x="650" y="110" text-anchor="middle" class="label">Reflection-based rules</text>
  <text x="650" y="125" text-anchor="middle" class="label">Dynamic invocation</text>

  <!-- Support Files -->
  <rect x="175" y="200" width="150" height="60" class="box"/>
  <text x="250" y="225" text-anchor="middle" class="text">rules.rb</text>
  <text x="250" y="245" text-anchor="middle" class="label">Sample predicates</text>

  <rect x="375" y="200" width="150" height="60" class="box"/>
  <text x="450" y="225" text-anchor="middle" class="text">facts.yml</text>
  <text x="450" y="245" text-anchor="middle" class="label">Test data</text>

  <!-- Advanced -->
  <rect x="200" y="320" width="400" height="80" class="box-advanced"/>
  <text x="400" y="350" text-anchor="middle" class="text">expert_system_simple.rb</text>
  <text x="400" y="370" text-anchor="middle" class="label">Backward-chaining goal planner</text>
  <text x="400" y="385" text-anchor="middle" class="label">Inference engine</text>

  <!-- Arrows -->
  <path d="M 250 100 L 295 100" class="arrow"/>
  <path d="M 500 100 L 545 100" class="arrow"/>
  <path d="M 250 140 L 250 195" class="arrow"/>
  <path d="M 450 140 L 450 195" class="arrow"/>
  <path d="M 550 140 Q 500 200 450 260" class="arrow"/>
  <path d="M 400 260 L 400 315" class="arrow"/>

  <text x="400" y="470" text-anchor="middle" class="label" style="font-size: 10px;">Complexity increases left to right, top to bottom</text>
</svg>
```

## Files

### test.rb
**Concept**: Basic method storage and invocation

Demonstrates how to capture methods from different contexts (top-level, modules, classes, instances) and store them in data structures for later invocation.

```ruby
# Key insight: Methods can be stored like any other object
method_ref = method(:some_method)
method_ref.call(args)
```

**Notable feature**: Uses `def` return value (method name as symbol) for compact storage.

### facts.yml
Test data for rule-based systems. Contains sample facts about people with ages.

```yaml
- { name: 'Alice', age: 15 }
- { name: 'Bob', age: 25 }
```

### rules.rb
Sample rule methods with various parameter signatures. Includes predicate methods like `teenagers?` and `adults?` that can be used by rule engines.

### get_optional_defaults.rb
**Concept**: AST introspection for parameter metadata

Uses RubyVM::AbstractSyntaxTree to extract default parameter values from method definitions. This enables dynamic analysis of method signatures.

**Known issue**: Line 62 references non-existent `:method_with_defaults` (should be `:method_with_optional_2nd_parameter`)

### rule_based_system.rb
**Concept**: Reflection-based rule engine

Most sophisticated piece. Uses Ruby's reflection API to:
- Introspect method parameters (required, optional, keyword)
- Build rules from method definitions
- Match facts against rule parameters
- Execute rules dynamically

Features a `Reflection` module that provides rich parameter metadata.

**Known issues**:
- Exit on line 160 prevents example code from running
- References `rules.txt` which doesn't exist
- Uses `puts` instead of `debug_me` gem

### expert_system_simple.rb
**Concept**: Backward-chaining inference engine

Implements a goal-oriented planner that works backward from desired outcomes to determine necessary steps. More educational/conceptual than production code.

## Usage Examples

### Basic Method Storage (test.rb)
```ruby
ruby test.rb
```

### Rule-Based System (rule_based_system.rb)
```ruby
# Currently disabled due to exit on line 160
# Remove exit statement and ensure rules.txt exists
ruby rule_based_system.rb
```

### Expert System (expert_system_simple.rb)
```ruby
ruby expert_system_simple.rb
```

## Key Concepts Demonstrated

1. **Method Objects**: `method(:name)` captures a callable method reference
2. **Reflection**: `Method#parameters` introspects signatures
3. **AST Parsing**: `RubyVM::AbstractSyntaxTree` analyzes source structure
4. **Dynamic Invocation**: `method.call` executes stored methods
5. **Pattern Matching**: Rules match against fact hashes
6. **Inference**: Forward and backward chaining for logical deduction

## Known Issues

- [ ] `get_optional_defaults.rb:62` - wrong method name
- [ ] `rule_based_system.rb:160` - exit statement blocks execution
- [ ] Missing `rules.txt` file
- [ ] Code uses `puts` instead of `debug_me` gem
- [ ] No test coverage

## Strengths

- Progressive complexity showing clear learning/exploration path
- Creative use of Ruby's metaprogramming capabilities
- Good inline comments explaining limitations
- Interesting bridge between code-as-data and data-as-code
- Demonstrates that "not a true RETE algorithm" but captures core concepts

## Future Enhancements

- Replace `puts` with `debug_me` gem
- Add proper test suite
- Implement true RETE algorithm for production-ready rule engine
- Add pattern matching using Ruby 3.x pattern syntax
- Create visual rule debugger
- Add rule conflict resolution strategies

## References

- Ruby Method objects: https://ruby-doc.org/core/Method.html
- AST introspection: https://ruby-doc.org/core/RubyVM/AbstractSyntaxTree.html
- RETE algorithm: https://en.wikipedia.org/wiki/Rete_algorithm

## License

Experimental code - use at your own risk.
