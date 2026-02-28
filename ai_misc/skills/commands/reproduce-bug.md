---
name: reproduce-bug
description: Reproduce and investigate a bug using logs and console inspection
argument-hint: "[GitHub issue number]"
---

Look at github issue #$ARGUMENTS and read the issue description and comments.

Then, run the following agents in parallel to reproduce the bug:

1. Task rails-console-explorer(issue_description)
2. Task appsignal-log-investigator (issue_description)

Then think about the places it could go wrong looking at the codebase. Look for loggin output we can look for.

Then, run the following agents in parallel again to find any logs that could help us reproduce the bug.

1. Task rails-console-explorer(issue_description)
2. Task appsignal-log-investigator (issue_description)

Keep running these agents until you have a good idea of what is going on.

**Reference Collection:**

- [ ] Document all research findings with specific file paths (e.g., `app/services/example_service.rb:42`)

Then, add a comment to the issue with the findings and how to reproduce the bug.
