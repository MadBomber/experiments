# .../Foo/cli/commands/generate.rb

module Foo::CLI::Commands::Generate
  VERSION = "1.0.0-generate"

  Commands.register "generate", aliases: ["g"]
  Commands.register "generate version", PrintVersion.new(VERSION), aliases: %w[--version]
end


Dir.glob("#{__dir__}/generate/*.rb")
  .each do |file|
  # print "Loading #{file} ... "
  require_relative file
  # puts "done."
end

