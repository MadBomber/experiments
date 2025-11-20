# frozen_string_literal: true

require 'pg'
require 'uri'

class HTM
  # Database setup and configuration for HTM
  # Handles schema creation and TimescaleDB hypertable setup
  class Database
    class << self
      # Set up the HTM database schema
      #
      # @param db_url [String] Database connection URL (uses ENV['TIGER_DBURL'] if not provided)
      # @return [void]
      #
      def setup(db_url = nil)
        config = parse_connection_url(db_url || ENV['TIGER_DBURL'])

        raise "Database configuration not found. Please source ~/.bashrc__tiger" unless config

        conn = PG.connect(config)

        # Verify TimescaleDB is available
        verify_extensions(conn)

        # Run schema
        run_schema(conn)

        # Convert tables to hypertables for time-series optimization
        setup_hypertables(conn)

        conn.close
        puts "✓ HTM database schema created successfully"
      end

      # Parse database connection URL
      #
      # @param url [String] Connection URL
      # @return [Hash, nil] Connection configuration hash
      #
      def parse_connection_url(url)
        return nil unless url

        uri = URI.parse(url)
        params = URI.decode_www_form(uri.query || '').to_h

        {
          host: uri.host,
          port: uri.port,
          dbname: uri.path[1..-1],  # Remove leading /
          user: uri.user,
          password: uri.password,
          sslmode: params['sslmode'] || 'prefer'
        }
      end

      # Build config from individual environment variables
      #
      # @return [Hash, nil] Connection configuration hash
      #
      def parse_connection_params
        return nil unless ENV['TIGER_DBNAME']

        {
          host: ENV['TIGER_DBHOST'] || 'cw7rxj91bm.srbbwwxn56.tsdb.cloud.timescale.com',
          port: (ENV['TIGER_DBPORT'] || 37807).to_i,
          dbname: ENV['TIGER_DBNAME'],
          user: ENV['TIGER_DBUSER'],
          password: ENV['TIGER_DBPASS'],
          sslmode: 'require'
        }
      end

      # Get default database configuration
      #
      # @return [Hash, nil] Connection configuration hash
      #
      def default_config
        # Prefer TIGER_DBURL if available
        if ENV['TIGER_DBURL']
          parse_connection_url(ENV['TIGER_DBURL'])
        elsif ENV['TIGER_DBNAME']
          parse_connection_params
        else
          nil
        end
      end

      private

      def verify_extensions(conn)
        # Check TimescaleDB
        timescale = conn.exec("SELECT extversion FROM pg_extension WHERE extname='timescaledb'").first
        if timescale
          puts "✓ TimescaleDB version: #{timescale['extversion']}"
        else
          puts "⚠ Warning: TimescaleDB extension not found"
        end

        # Check pgvector
        pgvector = conn.exec("SELECT extversion FROM pg_extension WHERE extname='vector'").first
        if pgvector
          puts "✓ pgvector version: #{pgvector['extversion']}"
        else
          puts "⚠ Warning: pgvector extension not found"
        end

        # Check pg_trgm
        pg_trgm = conn.exec("SELECT extversion FROM pg_extension WHERE extname='pg_trgm'").first
        if pg_trgm
          puts "✓ pg_trgm version: #{pg_trgm['extversion']}"
        else
          puts "⚠ Warning: pg_trgm extension not found"
        end
      end

      def run_schema(conn)
        schema_path = File.expand_path('../../sql/schema.sql', __dir__)
        schema_sql = File.read(schema_path)

        puts "Creating HTM schema..."

        # Remove extension creation lines - extensions are already available on TimescaleDB Cloud
        # This avoids path issues with control files
        schema_sql_filtered = schema_sql.lines.reject { |line|
          line.strip.start_with?('CREATE EXTENSION')
        }.join

        begin
          conn.exec(schema_sql_filtered)
          puts "✓ Schema created"
        rescue PG::Error => e
          # If schema already exists, that's OK
          if e.message.match?(/already exists/)
            puts "✓ Schema already exists (updated if needed)"
          else
            raise e
          end
        end
      end

      def setup_hypertables(conn)
        # Convert operations_log to hypertable for time-series optimization
        begin
          conn.exec(
            "SELECT create_hypertable('operations_log', 'timestamp',
             if_not_exists => TRUE,
             migrate_data => TRUE)"
          )
          puts "✓ Created hypertable for operations_log"
        rescue PG::Error => e
          puts "Note: operations_log hypertable: #{e.message}" if e.message !~ /already a hypertable/
        end

        # Optionally convert nodes table to hypertable partitioned by created_at
        begin
          conn.exec(
            "SELECT create_hypertable('nodes', 'created_at',
             if_not_exists => TRUE,
             migrate_data => TRUE)"
          )
          puts "✓ Created hypertable for nodes"

          # Enable compression for older data
          conn.exec(
            "ALTER TABLE nodes SET (
             timescaledb.compress,
             timescaledb.compress_segmentby = 'robot_id,type'
            )"
          )

          # Add compression policy: compress chunks older than 30 days
          conn.exec(
            "SELECT add_compression_policy('nodes', INTERVAL '30 days',
             if_not_exists => TRUE)"
          )
          puts "✓ Enabled compression for nodes older than 30 days"
        rescue PG::Error => e
          puts "Note: nodes hypertable: #{e.message}" if e.message !~ /already a hypertable/
        end
      end
    end
  end
end
