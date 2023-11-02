# .../Foo/cli/commands/echo.rb

class Commands::Echo < Commands::Base
  Commands.register "echo", self

  desc "Print input"

  argument :input, desc: "Input to print"

  example [
    "             # Prints 'wuh?'",
    "hello, folks # Prints 'hello, folks'"
  ]

  def call(input: nil, **options)
    if input.nil?
      puts "wuh?"
    else
      puts input
    end
  end
end

