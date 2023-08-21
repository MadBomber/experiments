Here's an example program that demonstrates the usage of the `tty-option` gem in Ruby:

```ruby
require 'tty-option'

# Define a common class with common options
class CommonOptions
  include TTY::Option

  option :verbose do
    short '-v'
    long '--verbose'
    desc 'Enable verbose output'
  end

  option :dry_run do
    short '-d'
    long '--dry-run'
    desc 'Perform a dry run'
  end
end

# Define the first command class
class One
  include TTY::Option

  usage do
    program 'my_program'
    command 'one'
    desc 'Command one description'
  end

  # Include the common options
  CommonOptions.include_in(self)

  option :option_one do
    short '-o'
    long '--option-one'
    desc 'Option one description'
  end

  # Define the behavior of the command
  def execute
    # Your logic here
  end
end

# Define the second command class
class Two
  include TTY::Option

  usage do
    program 'my_program'
    command 'two'
    desc 'Command two description'
  end

  # Include the common options
  CommonOptions.include_in(self)

  option :option_two do
    short '-t'
    long '--option-two'
    desc 'Option two description'
  end

  # Define the behavior of the command
  def execute
    # Your logic here
  end
end

# Handle command line arguments
case ARGV[0]
when 'one'
  One.new.parse
when 'two'
  Two.new.parse
else
  puts <<~USAGE
    Usage: my_program [options] <command>

    Commands:
      one  Command one description
      two  Command two description

    Options:
      -v, --verbose   Enable verbose output
      -d, --dry-run   Perform a dry run
  USAGE
end
```

When executing this program with either the `'one'` or `'two'` command, it will parse the command-specific options as well as the common options. If the program is executed without specifying a valid command, it will print a help usage message in the Markdown format that lists the available commands and common options.
