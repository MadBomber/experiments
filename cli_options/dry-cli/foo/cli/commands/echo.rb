# .../Foo/cli/commands/echo.rb

class Commands::Echo < Commands::Base
  Commands.register "echo", self

  desc "Print input"

  argument :input, desc: "Input to print"

  option :float,
    aliases: %w[ -f --fp --float ],
    type: :float,
    default: 12.34,
    desc: "An floating point number"

  option :integer,
    aliases: %w[ -i --int --integer ],
    type: :integer,
    default: 123,
    desc: "An Integer number"

  example [
    "             # Prints 'wuh?'",
    "hello, folks # Prints 'hello, folks'"
  ]

  def call(input: nil, **options)

    debug_me{[
      :options
    ]}


    if input.nil?
      puts "wuh?"
    else
      puts input
    end
  end
end

