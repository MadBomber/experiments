# frozen_string_literal: true

require "active_record"
require "neighbor"

module FactDb
  module Database
    class << self
      def establish_connection!(config = FactDb.config)
        ActiveRecord::Base.establish_connection(config.database_url)
        ActiveRecord::Base.logger = config.logger if config.logger
      end

      def connected?
        ActiveRecord::Base.connected?
      end

      def migrate!
        establish_connection! unless connected?
        migrations_path = File.expand_path("../../db/migrate", __dir__)
        ActiveRecord::MigrationContext.new(migrations_path).migrate
      end

      def rollback!(steps = 1)
        establish_connection! unless connected?
        migrations_path = File.expand_path("../../db/migrate", __dir__)
        ActiveRecord::MigrationContext.new(migrations_path).rollback(steps)
      end

      def reset!
        establish_connection! unless connected?
        ActiveRecord::Base.connection.tables.each do |table|
          next if table == "schema_migrations"
          ActiveRecord::Base.connection.drop_table(table, if_exists: true, force: :cascade)
        end
        migrate!
      end

      def schema_version
        establish_connection! unless connected?
        ActiveRecord::SchemaMigration.all.map(&:version).max || 0
      end
    end
  end
end
