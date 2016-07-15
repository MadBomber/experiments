require 'java'
require 'jruby/core_ext'
require 'bundler/setup'
Bundler.require

task "db:migrate" do
  require './db/init'
  Sequel.extension :migration
  Sequel::Migrator.run(DB, 'db/migrations')
end

task "assets:precompile" do
  require 'jbundler'
  config = JBundler::Config.new
  JBundler::LockDown.new( config ).lock_down
  JBundler::LockDown.new( config ).lock_down("--vendor")
end
