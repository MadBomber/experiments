# .../sqa/cli/command/start.rb

module SQA::CLI::Command
class Start < Base
  VERSION = "0.0.1-start"

  Command.register "start", self
  Command.register "start version", PrintVersion.new(VERSION), aliases: %w[--version]

  desc "Start Foo machinery"

  argument :root, required: true, desc: "Root directory"

  example [
    "path/to/root # Start Foo at root directory"
  ]

  def call(root:, **options)
    debug_me{[ :options ]}
    puts "started - root: #{root}"
  end
end
end
