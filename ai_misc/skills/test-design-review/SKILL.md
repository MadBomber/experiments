---
description: Review tests for design quality. One subagent per principle. Use after writing tests or to audit an existing test file.
argument-hint: [file or diff to review — defaults to current branch diff vs main]
---

# Test Design Review

When invoked, review the specified tests (or the diff if none specified) against the guidelines in this document.

Note: all the following steps should be followed, strictly and literally, even for trivial-seeming changes.

1. Unless otherwise specified, set your scope to the diff between the current branch and master/main. Don't neglect test code — it's just as important as application code.
2. Start a running list of principle violations.
3. Grab the first principle in this document, announce to the user that you're looking for violations of it, and, using a sub-agent, look for violations. Do not group principles. Strictly use one agent per principle.
4. For the worst 1-3 offenses of that principle, add a description of the violation to the running list.
5. Sort the list from worst offenses to most minor.
6. Notify the user that the design review is complete.
7. Show the list of violations to the user, then apply the fixes.

---

## Core Principle

Tests are executable specifications. A specification answers: "In scenario X, what should happen?"

## Specification Format

Good: "When the user submits an empty form, display a validation error."
Good: "When the API returns 500, show a graceful error message."
Good: "When no records exist, display 'No results found'."

Bad: "It works correctly." (What does 'correctly' mean?)
Bad: "It handles errors." (Which errors? How?)
Bad: "It validates input." (What validation? What happens on failure?)

The scenario lives in the test method name. Name methods as `test_<what>_when_<scenario>` or `test_<scenario>_<expected_outcome>`. Never use generic names like `test_works_correctly` or `test_handles_errors`.

Bad:
```ruby
def test_label_returns_correct_value
  run = TestSuiteRun.new(status: "passed")
  assert_equal "Passed", run.label
end
```

Good:
```ruby
def test_label_returns_passed_when_status_is_passed
  run = TestSuiteRun.new(status: "passed")
  assert_equal "Passed", run.label
end
```

## Test Behavior, Not Implementation Details

Bad:
```ruby
def test_marks_particles_position_blue
  world = World.new(10, 10)
  world.tick
  assert_equal 0x0000FF, world.color_at(5, 0)
end
```

Good:
```ruby
def test_cell_turns_particles_color_when_particle_touches_it
  world = World.new(10, 10)
  particle_color = world.particle_color
  particle_position = world.particle_position

  world.tick

  assert_equal particle_color, world.color_at(particle_position[0], particle_position[1])
end
```

## When Capturing Scenarios, Describe the Essence

Bad:
```ruby
class ScopeFailedTest < Minitest::Test
```

Good:
```ruby
class RerunOnlyFailedTestsTest < Minitest::Test
```

## Avoid Arbitrariness

### Avoid .first and .last in Tests

Using `.first` or `.last` is fragile because it depends on ordering, which can change. Instead use explicit queries.

Bad:
```ruby
post repositories_path, params: { repo_full_name: "jasonswett/ductwork" }
repository = Repository.last
assert_equal @github_account, repository.github_account
```

Good:
```ruby
assert_difference -> { Repository.where(github_account: @github_account).count }, 1 do
  post repositories_path, params: { repo_full_name: "jasonswett/ductwork" }
end
```

## Make Assertions About What's Essential, Not What's Incidental

Only assert what matters. Don't assert things that are implied by other assertions or are implementation details.

Bad:
```ruby
assert_response :success   # redundant noise
assert_not_includes response.body, "deleted_item"
```

Good:
```ruby
assert_not_includes response.body, "deleted_item"
```

If the response wasn't successful, the body assertion tells you something went wrong. The status check adds nothing.

## Don't Mix Levels of Abstraction

Keep test setup, action, and assertion at the same level of abstraction. Extract incidental mechanics into helper methods placed *after* the test that uses them.

Bad — raw mechanics inline:
```ruby
def test_does_not_query_database_on_subsequent_calls
  dispatcher = Dispatcher.new

  query_count = 0
  callback = lambda { |*, _| query_count += 1 }
  ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
    dispatcher.results
    count_after_first = query_count
    dispatcher.results
    assert_equal count_after_first, query_count
  end
end
```

Good — essential meaning is visible; mechanics hidden in a helper:
```ruby
def test_does_not_query_database_on_subsequent_calls
  dispatcher = Dispatcher.new

  first_call_count = count_queries { dispatcher.results }
  second_call_count = count_queries { dispatcher.results }

  assert_equal 0, second_call_count
end

private

def count_queries(&block)
  count = 0
  callback = lambda { |*, _| count += 1 }
  ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)
  count
end
```

## Don't Write Pointless / Tautological Tests

Bad:
```ruby
def test_renders_checkbox_for_each_account
  first = create(:github_account, account_name: "first-account")
  second = create(:github_account, account_name: "second-account")

  get admin_job_runs_path

  doc = Nokogiri::HTML(response.body)
  assert_equal first.id, labeled_checkbox_value(doc, "first-account")
  assert_equal second.id, labeled_checkbox_value(doc, "second-account")
end
```

Tests like this merely answer: "Is the code I wrote the code I wrote?" There's no point.

## Assert on Observable Outcomes, Not Method Calls

When testing whether something happened, assert on the observable end result rather than whether a specific method was called.

Bad:
```ruby
def test_queues_the_task
  worker_pool = Minitest::Mock.new
  worker_pool.expect :queue_task, nil, [@task]
  WorkerPool.stub :new, worker_pool do
    QueueUnqueuedTasksJob.new.perform
  end
  worker_pool.verify
end
```

Good:
```ruby
def test_queues_the_task
  assert_difference -> { TaskEvent.where(name: "queued").count }, 1 do
    QueueUnqueuedTasksJob.new.perform
  end
end
```

The bad version tests means (was this method called?). The good version tests ends (did the thing actually happen?). Stub only what you must (external services), and let real code run so you can assert on real outcomes.

## Test Ends, Not Means

When testing a performance optimization like caching, don't assert on the mechanism. Assert on the observable difference.

Bad:
```ruby
def test_caches_the_result
  @run.duration
  assert_not_nil Rails.cache.read("test_suite_run/#{@run.id}/duration")
end
```

Good:
```ruby
def test_does_not_query_database_on_subsequent_calls
  @run.duration

  second_call_count = count_queries { @run.duration }

  assert_equal 0, second_call_count
end
```

## Use Arrange / Act / Assert Format

Each test should have a clear Arrange → Act → Assert structure. Shared setup goes in `setup`; test-specific arrange stays in the test method.

Bad — setup mixed into test body with assertions:
```ruby
def test_shows_finished_status_in_sidebar
  task = create(:task, :dispatched)
  test_suite_run = task.test_suite_run
  login_as(test_suite_run.repository.user)
  visit test_suite_run_path(test_suite_run)
  assert_text "Running"
  task.update!(exit_code: 0)
  assert_text "Passed"
end
```

Good — shared setup separated, single clear assertion:
```ruby
class SidebarStatusTest < ActionDispatch::IntegrationTest
  def setup
    @task = create(:task, :dispatched)
    @test_suite_run = @task.test_suite_run
    login_as(@test_suite_run.repository.user)
  end

  def test_shows_passed_when_test_suite_run_finishes
    # Act
    visit test_suite_run_path(@test_suite_run)
    @task.update!(exit_code: 0)

    # Assert
    assert_text "Passed"
  end
end
```

## Don't Use Hacks to Test Private Methods

Never use `#send` or `#public_send` to call private methods in tests. If you feel compelled to test a private method directly, make it public. It's usually an acceptable price.

## No Speculative Coding

Scrutinize choices like `sleep 0.1` or `wait: 3`. Are they actually needed, or were they cargo-culted? Question all such choices.

## Miscellaneous

Never use `instance_variable_set` in tests. If it seems like the only option, that's a sign of poor design — pause, find the design problem, and suggest a refactor.
