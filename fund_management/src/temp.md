You're correct, you're missing a require statement for the Minitest::Reporters. To fix this issue, you need to add the following line near the top of your file, along with the other require statements:

```ruby
require 'minitest/reporters'
```

Here's the updated version of your script with the missing require and some minor formatting adjustments to match your specified style:

```ruby
#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.expand_path(__dir__))

require 'pathname'
require 'json'
require 'time'
require 'minitest/autorun'
require 'minitest/reporters'

# This file serves as a test helper, running all test files
# matching the pattern *_test.rb in the 'test' directory.
# It uses modern Ruby 3.3 syntax and follows specific
# formatting guidelines.

# Configuration
CONFIG = {
  test_directory: 'test',
  pattern:        '*_test.rb',
  verbose:        true,
  timeout:        30
}

# Collect all test files
def collect_test_files(directory:, pattern:)
  test_dir = Pathname.new(directory)

  unless test_dir.directory?
    puts "Error: '#{directory}' is not a valid directory."
    exit 1
  end

  test_files = test_dir.glob(pattern)

  if test_files.empty?
    puts "No test files found matching '#{pattern}' in " \
         "'#{directory}'."
    exit 0
  end

  test_files
end

# Load all test files
test_files = collect_test_files(directory: CONFIG[:test_directory],
                                pattern:   CONFIG[:pattern])

test_files.each do |file|
  require file
end

# Configure Minitest
Minitest.autorun

Minitest::Reporters.use!(
  Minitest::Reporters::SpecReporter.new,
  ENV,
  Minitest.backtrace_filter
) if CONFIG[:verbose]

# Set timeout for tests
Minitest.after_run do
  exit 1 if Minitest.run_command(['--seed', Random.new_seed.to_s]) > 0
end

Timeout.timeout(CONFIG[:timeout]) do
  Minitest.run
end

puts "All tests completed."
```

This should resolve the `uninitialized constant Minitest::Reporters::SpecReporter` error you were encountering. The script now properly requires the `minitest/reporters` library, which provides the `SpecReporter` class.

