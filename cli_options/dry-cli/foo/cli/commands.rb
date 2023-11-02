# Foo/cli/commands.rb

# Establish the Commands registry
module Foo::CLI::Commands
  extend Dry::CLI::Registry
end


# Create a short-cut to the registry
Commands = Foo::CLI::Commands

load_these_first = [
  # TODO: will need the overloaded help here as well
  "#{__dir__}/commands/base.rb",
  "#{__dir__}/commands/version.rb",
].each { |file| require_relative file }

Dir.glob("#{__dir__}/commands/*.rb")
  .reject{|file| load_these_first.include? file}
  .each do |file|
  # print "Loading #{file} ... "
  require_relative file
  # puts "done."
end


Foo::CLI::Commands.before("my_help") { print "\n== TOP Header ==\n\n" }
Foo::CLI::Commands.after("my_help")  { print "\n\n== TOP Footer ==\n" }
