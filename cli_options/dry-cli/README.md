# experiments/cli_options/dry-cli/README.md

This is an example of how to use the dry-cli gem in a large complex environment where external "commands" may be provided through 3rd part extensions.

I'm looking at it for use with my SQA gem.  That's why the namespace starts with SQA rather than the Foo module used by the dry-cli gem's example.

I took the original dry-cli example which is provided in a single file and broke it up into multiple files to demonstrate the ability to drynamically register commands and sub-commands without know the namespace.

For third part developers the instructions would be something like this:

To define a new command as a gem for use with the SQA framework setup this file structure in you gem's lib directory

```plaintext

sqa
└── cli
    └── command
        |-- xyzzy
 			  └── xyzzy.rb

```

Where xyzzy.rb is the file that implements your command. You can put additional files into the xyzzy that support your command.

You command file xyzzy.rb should look something like this:

```ruby
class Command::Xyzzy < Command::Base
	VERSION = "1.0.0-xyzzy"

	# :help, :debug and :verbose are automatically defined

	# your DRY::CLI options if any specific to your command

	Command.register "xyzzy", self #, aliases: %w[ whatever you want]
	Command.register "xyzzy version", PrintVersion.new(VERSION), aliases: %w[--version]

	def initialize(*)
		# whatever you need
	end

	def call(*)
		# your command business logic starts here
	end
end
```

