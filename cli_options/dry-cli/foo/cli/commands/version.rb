# .../Foo/cli/commands/version.rb

class Commands::Version < Commands::Base
  Commands.register "version", self, aliases: %w[--version]

  desc "Print version"

  def initialize(version=Foo::VERSION)
    @version = version
  end

  def call(**options)
    puts @version
    exit(0)
  end
end

# Create a short-cut to the class
PrintVersion = Commands::Version
