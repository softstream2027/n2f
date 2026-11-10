#!/bin/sh
# Extension "unaccent" requise par Axelor (guide d'installation AOS 9).
# S'exécute uniquement à la première initialisation du volume PostgreSQL.
set -e
for db in template1 "$POSTGRES_DB"; do
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" \
    -c "CREATE EXTENSION IF NOT EXISTS unaccent;"
done
