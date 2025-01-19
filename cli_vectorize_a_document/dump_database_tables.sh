#!/usr/bin/env bash
# dump_database_tables.sh

for table in "documents" "contents" "structures" "embeddings"; do
  echo "$table ..."
  pg_dump -U postgres -d dv_development -t "$table" --no-owner --no-privileges --file="${table}.sql"
done
