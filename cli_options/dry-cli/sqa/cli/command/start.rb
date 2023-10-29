# .../sqa/cli/command/start.rb

module SQA::CLI::Command
class Start < Base
  SQA::CLI::Command.register "start", self

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
