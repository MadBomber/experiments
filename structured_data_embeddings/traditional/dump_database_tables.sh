#!/usr/bin/env bash
# dump_database_tables.sh

for table in "embeddings"; do
  echo "$table ..."
  pg_dump -U postgres -d vahraipilot -t "$table" --no-owner --no-privileges --file="sql/dumps/${table}.sql"
done
