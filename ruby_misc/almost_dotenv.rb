# experiments/ruby_misc/almost_dotenv.rb

# The dotenv gem is a nice functionality that I use often.
# The following two lines implement a very basic form of the dotenv
# functionality.

regexp = /^(\w+)=['"]?(.+?)['"]?$/

ENV.update File.read(".env").scan(regexp).to_h if File.exist?(".env")

