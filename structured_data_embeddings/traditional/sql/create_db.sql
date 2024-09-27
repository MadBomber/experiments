-- sql/create_db.sql

-- Drop the database if it exists
DROP DATABASE IF EXISTS sd;

-- Create the database
CREATE DATABASE sd;

-- Connect to the newly created database
\c sd

-- pgVector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Full-text search extensions
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS tsm_system_rows;
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
