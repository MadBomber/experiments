class CreateExtensions < ActiveRecord::Migration[6.0]
  def change
    # Create the vector extension
    enable_extension 'vector' unless extension_enabled?('vector')

    # Full-text search and other required extensions
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
    enable_extension 'btree_gin' unless extension_enabled?('btree_gin')
    enable_extension 'btree_gist' unless extension_enabled?('btree_gist')
    enable_extension 'tsm_system_rows' unless extension_enabled?('tsm_system_rows')
    enable_extension 'postgres_fdw' unless extension_enabled?('postgres_fdw')
  end
end
