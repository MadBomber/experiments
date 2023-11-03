# .../Foo/cli/commands/stop.rb

class Commands::Stop < Commands::Base
  VERSION = '0.1.0-stop'

  Commands.register "stop", self
  Commands.register "stop version", PrintVersion.new(VERSION), aliases: %w[--version]

  header "== STOP Header =="
  footer "== STOP Footer =="

  desc "Stop Foo machinery"

  option :graceful, type: :boolean, default: true, desc: "Graceful stop"

  def call(**options)
    puts "stopped - graceful: #{options.fetch(:graceful)}"
  end
end

