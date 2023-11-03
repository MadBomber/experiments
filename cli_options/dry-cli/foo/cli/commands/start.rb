# .../Foo/cli/commands/start.rb

class Commands::Start < Commands::Base
  VERSION = "0.0.1-start"

  Commands.register "start", self
  Commands.register "start version", PrintVersion.new(VERSION), aliases: %w[--version]

  header "== Start Header =="
  footer "== Start Footer =="

  desc "Start Foo machinery"

  argument :root,
    required: true,
    desc:     "Root directory"

  example [
    "path/to/root # Start Foo at root directory"
  ]

  def call(root:, **options)
    puts "started - root: #{root}"
  end
end
