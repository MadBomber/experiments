#!/usr/bin/env ruby
# Test connection to TimescaleDB and verify extensions

require 'pg'
require 'uri'

# Parse connection URL
db_url = ENV['TIGER_DBURL']
unless db_url
  puts "ERROR: TIGER_DBURL environment variable not set"
  exit 1
end

uri = URI.parse(db_url)
params = URI.decode_www_form(uri.query || '').to_h

config = {
  host: uri.host,
  port: uri.port,
  dbname: uri.path[1..-1],
  user: uri.user,
  password: uri.password,
  sslmode: params['sslmode'] || 'prefer'
}

puts "Connecting to TimescaleDB..."
puts "Host: #{config[:host]}"
puts "Port: #{config[:port]}"
puts "Database: #{config[:dbname]}"
puts "User: #{config[:user]}"
puts

begin
  conn = PG.connect(config)
  puts "✓ Connected successfully!"
  puts

  # Check PostgreSQL version
  version = conn.exec("SELECT version()").first['version']
  puts "PostgreSQL Version:"
  puts "  #{version}"
  puts

  # Check TimescaleDB
  timescale = conn.exec("SELECT extversion FROM pg_extension WHERE extname='timescaledb'").first
  if timescale
    puts "✓ TimescaleDB Extension:"
    puts "  Version: #{timescale['extversion']}"
  else
    puts "✗ TimescaleDB extension not installed"
  end
  puts

  # Check pgvector
  pgvector = conn.exec("SELECT extversion FROM pg_extension WHERE extname='vector'").first
  if pgvector
    puts "✓ pgvector Extension:"
    puts "  Version: #{pgvector['extversion']}"
  else
    puts "⚠ pgvector extension not installed (will need to install)"
  end
  puts

  # Check pg_trgm
  pg_trgm = conn.exec("SELECT extversion FROM pg_extension WHERE extname='pg_trgm'").first
  if pg_trgm
    puts "✓ pg_trgm Extension:"
    puts "  Version: #{pg_trgm['extversion']}"
  else
    puts "⚠ pg_trgm extension not installed (will need to install)"
  end
  puts

  # List all available extensions
  puts "All installed extensions:"
  extensions = conn.exec("SELECT extname, extversion FROM pg_extension ORDER BY extname")
  extensions.each do |ext|
    puts "  - #{ext['extname']} (#{ext['extversion']})"
  end
  puts

  # Check current database size
  size = conn.exec("SELECT pg_size_pretty(pg_database_size(current_database()))").first
  puts "Database Size: #{size['pg_size_pretty']}"
  puts

  conn.close
  puts "✓ Connection test completed successfully!"

rescue PG::Error => e
  puts "✗ Connection failed:"
  puts "  #{e.message}"
  exit 1
end
