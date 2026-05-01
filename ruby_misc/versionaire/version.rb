# experiments/ruby_misc/versionaire/version.rb

require 'versionaire'

module MyApp
  VERSION_FILEPATH  = "#{__dir__}/.version"
  VERSION           = Versionaire::Version File.read(VERSION_FILEPATH).strip
  def self.version  = VERSION
end

puts MyApp::VERSION.class
puts MyApp::VERSION
puts MyApp.version
new_version = MyApp::VERSION.bump :major
puts new_version

File.open(MyApp::VERSION_FILEPATH, 'w').write new_version
puts File.read(MyApp::VERSION_FILEPATH).strip
