# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

namespace :db do
  desc "Run database migrations"
  task :migrate do
    require_relative "lib/fact_db"
    FactDb.configure do |config|
      config.database_url = ENV.fetch("DATABASE_URL")
    end
    FactDb::Database.migrate!
  end

  desc "Rollback the last migration"
  task :rollback do
    require_relative "lib/fact_db"
    FactDb.configure do |config|
      config.database_url = ENV.fetch("DATABASE_URL")
    end
    FactDb::Database.rollback!
  end

  desc "Reset the database (drop, create, migrate)"
  task :reset do
    require_relative "lib/fact_db"
    FactDb.configure do |config|
      config.database_url = ENV.fetch("DATABASE_URL")
    end
    FactDb::Database.reset!
  end
end

task default: :test
