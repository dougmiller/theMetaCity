#!/bin/bash
set -e
# Everything Alembic does NOT own: schemas, the alembic version schema, and the
# grants that make the read-only engine safe. Alembic (flask db upgrade, run by
# the flask container entrypoint) creates all TABLES afterwards. PostgreSQL 18
# provides uuidv7() / uuid_extract_timestamp() natively.
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<SQL
    CREATE SCHEMA IF NOT EXISTS com               AUTHORIZATION tmc_master;
    CREATE SCHEMA IF NOT EXISTS media             AUTHORIZATION tmc_master;
    CREATE SCHEMA IF NOT EXISTS everyday_ordinary AUTHORIZATION tmc_master;
    CREATE SCHEMA IF NOT EXISTS alembic           AUTHORIZATION tmc_master;

    GRANT USAGE ON SCHEMA com, media, everyday_ordinary TO tmc_selector;
    ALTER DEFAULT PRIVILEGES FOR ROLE tmc_master IN SCHEMA com, media, everyday_ordinary
        GRANT SELECT ON TABLES TO tmc_selector;
SQL
echo "Schemas + grants created."
