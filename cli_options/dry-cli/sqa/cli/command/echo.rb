# .../sqa/cli/command/echo.rb

module SQA::CLI::Command
class Echo < Base
  SQA::CLI::Command.register "echo", self

  desc "Print input"

  argument :input, desc: "Input to print"

  example [
    "             # Prints 'wuh?'",
    "hello, folks # Prints 'hello, folks'"
  ]

  def call(input: nil, **options)
    debug_me{[ :options ]}
    if input.nil?
      puts "wuh?"
    else
      puts input
    end
  end
end
end
