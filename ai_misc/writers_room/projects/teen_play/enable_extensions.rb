#!/usr/bin/env ruby
# Enable required PostgreSQL extensions

require 'pg'
require 'uri'

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
conn = PG.connect(config)

# Enable pg_trgm for fuzzy text matching
puts "Enabling pg_trgm extension..."
begin
  conn.exec("CREATE EXTENSION IF NOT EXISTS pg_trgm")
  version = conn.exec("SELECT extversion FROM pg_extension WHERE extname='pg_trgm'").first
  puts "✓ pg_trgm enabled (version #{version['extversion']})"
rescue PG::Error => e
  puts "✗ Failed to enable pg_trgm: #{e.message}"
end

puts
puts "Summary of extensions for HTM:"
puts

# Check all required extensions
required = {
  'timescaledb' => 'Time-series optimization',
  'vector' => 'Vector similarity search (pgvector)',
  'pg_trgm' => 'Fuzzy text matching',
  'ai' => 'AI/ML helpers (bonus)',
  'vectorscale' => 'Enhanced vector search (bonus)'
}

required.each do |ext_name, description|
  result = conn.exec("SELECT extversion FROM pg_extension WHERE extname='#{ext_name}'").first
  if result
    puts "✓ #{ext_name.ljust(15)} v#{result['extversion'].ljust(10)} - #{description}"
  else
    puts "✗ #{ext_name.ljust(15)} NOT INSTALLED - #{description}"
  end
end

conn.close
puts
puts "✓ Extension setup complete!"
