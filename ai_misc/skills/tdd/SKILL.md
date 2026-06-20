---
description: Implement a change using test-driven development with Minitest. Guides the specify-encode-fulfill workflow with spec clarification, clean-kitchen checks, and design reviews after each test.
argument-hint: [specification — what you want to build]
---

# Test-Driven Development

## Initial Specification

$ARGUMENTS

## The Specify-Encode-Fulfill Loop

1. **Specify**: Come up with the specifications for what you want to build
2. **Encode**: Encode those specifications as automated tests (executable specifications)
3. **Fulfill**: Write the code to fulfill the specifications

At a finer grain:

1. Write a list of the specifications within scope of the current TDD session
2. Encode one item in the list as an automated test
3. Change the code *just barely enough* to *make the current test failure go away*. Avoid speculative coding — if we write more code than necessary, we risk having code that is never exercised by any test
4. Optionally refactor, but not before committing the behavior change. Never mix behavior changes with refactoring
5. Until the list is empty, go back to #2

This follows Kent Beck's [Canon TDD](https://tidyfirst.substack.com/p/canon-tdd).

## Clarifying Specifications

Before writing tests, follow this loop:

1. Repeat my specifications back to me in your own words
2. Ask me to confirm your articulation is correct, or explain how it's wrong
3. If confirmed, proceed to writing tests; otherwise use my response and go back to step 1

Specifications should take the form: "under scenario A, X happens; under scenario B, Y happens."

For guidance on designing good specifications, see [test-design-review/SKILL.md](../test-design-review/SKILL.md).

## Translating Specifications into Tests

Each scenario maps to one test method. The scenario lives in the method name. Use the pattern `test_<expected_outcome>_when_<scenario>` or `test_<scenario>_<expected_outcome>`.

If the specification is "when a test suite run's status is 'passed', its label says 'Passed'", the test should look like:

```ruby
class TestSuiteRunTest < Minitest::Test
  def test_label_returns_passed_when_status_is_passed
    test_suite_run = TestSuiteRun.new(status: "passed")
    assert_equal "Passed", test_suite_run.label
  end
end
```

Bad:
```ruby
def test_label_returns_correct_value
  test_suite_run = TestSuiteRun.new(status: "passed")
  assert_equal "Passed", test_suite_run.label
end
```

Of course it returns the "correct" value. What else could we want? Never assert that behavior "works correctly", "works properly", or "handles" a scenario. Specify *what the correct behavior is*.

## Workflow

1. You invoke `/tdd` with a draft specification
2. After back-and-forth, we agree on "final" specifications
3. Check if we need to "clean the kitchen before making dinner" (see below)
4. Write just one test (per Canon TDD)
5. Show me the test and ask for approval before continuing
6. Write the application code, show it to me, and ask for approval before committing (see "Fulfilling Test Specifications" below)
7. I provide a new specification and we start over from step 2

### Cleaning the Kitchen

Before writing a test, picture the test you're going to write and where you'll put it. Does this new behavior slot tidily into the conceptual framework of the code where we'll be adding it? If not, is there a reconceptualization of the current behavior that would make the result more conceptually elegant?

If such a reconceptualization is called for, suggest it. If the user approves, abandon the current change, get to a clean working state, and on a new branch perform a refactoring. Then pause, consult the user, and begin again.

"Clean the kitchen before you make dinner."

### Fulfilling Test Specifications

Write ONLY ENOUGH CODE to make the current test failure go away. Never use "defensive coding" — defensive coding is almost always speculative coding (code added without justification from a test).

Once you've written the test, invoke a separate subagent with `/test-design-review` to scrutinize your test code. Then invoke another subagent with `/software-design-review` to scrutinize your application code.

### Don't Be Sloppy

This kind of thinking is bad:

> "That failure is pre-existing (unrelated to our change). Our new specs pass. Want me to commit and push?"

We don't make dinner in a dirty kitchen. If we discover a pre-existing failure, the right move is to pause, stash our changes, fix the pre-existing failure, then resume.

### Don't Be Lazy

This is bad:

> "Bundler version mismatch. The tests can't run here. But the changes are straightforward — the logic is simple."

Don't abandon tests immediately upon encountering the slightest difficulty.
