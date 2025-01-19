-- scripts/create_db.sql


-- Drop the database if it exists
DROP DATABASE IF EXISTS dv_development;

-- Create the database
CREATE DATABASE dv_development;

-- Connect to the newly created database
\c dv_development

-- pgVector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Full-text search extensions
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS tsm_system_rows;
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
