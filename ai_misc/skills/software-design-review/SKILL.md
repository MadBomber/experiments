---
description: Review code for design principle violations. One subagent per principle. Supports "fsd" arg for full self-driving mode (apply all fixes without prompting).
argument-hint: [fsd | file or diff to review — defaults to current branch diff vs main]
---

# Software Design Review

When invoked, unless otherwise directed, follow the steps below. Steps 1–6 are autonomous; step 7 is interactive. Pass `fsd` to enter full self-driving mode — apply all fixes to all violations without prompting.

This skill applies to test code just as much as application code.

Note: all steps should be followed, strictly and literally, even for trivial-seeming changes.

1. Unless otherwise specified, set your scope to the diff between the current branch and master/main. Don't neglect test code.
2. Start a running list of principle violations.
3. Grab the first principle in this document, announce to the user that you're looking for violations of it, and, using a sub-agent, look for violations. Do not group principles. Strictly use one agent per principle.
4. For the worst 1-3 offenses of that principle, add a description of the violation to the running list.
5. Sort the list from worst offenses to most minor.
6. Notify the user that the design review is complete.
7. For each violation, offer a solution and ask whether to apply it or move on. Apply each fix on its own branch, in atomic commits (unless the changes aren't committed yet, in which case branches don't apply). Follow TDD where applicable.

---

# Principles

## Call Things What They Are

Bad:
```ruby
retries = 0
begin
  token(installation_id)
rescue Octokit::InternalServerError
  retries += 1
  retry if retries < 3
  raise
end
```

`retries` isn't a retry — it's a retry COUNT. Same problem with `attempts`.

Good:
```ruby
retry_count = 0
begin
  token(installation_id)
rescue Octokit::InternalServerError
  retry_count += 1
  retry if retry_count < 3
  raise
end
```

## Be Strictly Consistent with Naming

If we have an instance of a `JobRunListQuery`, don't call it `query`. Call it `job_run_list_query`.

Bad:
```ruby
last_run = @repository.test_suite_runs.first
```

Is it a "run" or a "test suite run"?

Good:
```ruby
last_test_suite_run = @repository.test_suite_runs.first
```

Bad:
```ruby
ledger = PostageSummaryLedger.new
```

Good:
```ruby
postage_summary_ledger = PostageSummaryLedger.new
```

## Avoid Classically Bad Names

The worst variable name is `data` — it could be anything. The worst method name is `call`. They're not forbidden, but they're a smell. Flag them when they appear without good reason.

## No Hacks, No Workarounds

Bad — parsing a file with grep/cut instead of sourcing it:
```bash
API_KEY=$(grep '^API_KEY=' ../../.env | cut -d= -f2)
```

Good — just source it:
```bash
source ../../.env
```

Don't work around the problem. Find the real solution.

## No Speculative Coding

Don't write application code that is not strictly needed to satisfy an existing test. Every line of code should exist because a test requires it.

## Avoid Abbreviation

Bad:
```ruby
usr = User.first
```

Good:
```ruby
user = User.first
```

Exceptions: abbreviations already in everyone's vocabulary (URL, SSN, ID, etc.).

## Dependency Inversion Principle

High-level abstractions should not know about low-level or peripheral concerns. Specific behavior should live in the most specific class where it's relevant, not in a central/general class that's made to foot the bill.

Bad — general controller has deletion-specific logic:
```ruby
class ApplicationController < ActionController::Base
  def update_last_visited_page
    repository_id = @repository&.id || params[:repository_id]
    UpdateLastVisitedPageJob.perform_later(current_user.id, request.path, repository_id: repository_id)
  end
end
```

Good — repository concern pushed down to the specific controller:
```ruby
class ApplicationController < ActionController::Base
  def update_last_visited_page
    UpdateLastVisitedPageJob.perform_later(current_user.id, request.path)
  end
end

class RepositoriesController < ApplicationController
  def update_last_visited_repository
    user_preference = UserPreference.find_or_initialize_by(user_id: current_user.id)
    user_preference.update!(last_visited_repository: @repository)
  end
end
```

## Cohesion

Related code should be grouped together. The smell to look out for: a method added to a very central class (e.g. `User`) which exists only to support some peripheral feature. Such methods erode the host class's cohesion.

Bad — `GitHubAccount` carries a scope that only one admin view ever uses:
```ruby
class GitHubAccount < ApplicationRecord
  scope :active_repository_owners_first, lambda {
    # complex ordering logic for one admin page
  }
end
```

Good — scope logic lives in the controller that uses it:
```ruby
module Admin
  class JobRunsController < ApplicationController
    def index
      has_active_repository = Repository.where("repositories.github_account_id = github_accounts.id").active.arel.exists
      @github_accounts = GitHubAccount.order(Arel::Nodes::Descending.new(has_active_repository), :account_name)
      # ...
    end
  end
end
```

Leaf code (code nothing else depends on) can afford to be a bit messy. It's far better than polluting central classes.

## One Class, One File

Each class goes in its own file. No exceptions for "it's small."

## Favor Pure Functions

Avoid writing methods with side effects when a pure function would suffice.

## Name Methods for What They Return, Not What They Do

"What they do" is imperative. "What they return" is declarative.

Bad:
```ruby
def rendered_buffer(cells, width, height)
  # builds and returns buffer
end
```

Good:
```ruby
def buffer_with_cells(cells, width, height)
  # builds and returns buffer
end
```

## No Magic Numbers

Bad:
```ruby
retry if retry_count < 3
```

Good:
```ruby
RETRY_LIMIT = 3
retry if retry_count < RETRY_LIMIT
```

## No Premature Optimization

Don't assign a contrivedly-named temp var just to avoid calling a method twice.

Bad:
```ruby
to_dispatch = dispatchable_test_suite_runs(cluster: cluster)
to_dispatch.each do |run|
  # ...
end
```

Good:
```ruby
dispatchable_test_suite_runs(cluster: cluster).each do |run|
  # ...
end
```

## Keep Functions Focused

A function should do one thing. If you need to read a function and track several different concerns at once, it's doing too much. Extract.

## No Speculative Generalizations

Don't create abstractions for cases that don't exist yet. YAGNI. If there's only one caller, there's no need for a configurable strategy, a plugin system, or a base class.
