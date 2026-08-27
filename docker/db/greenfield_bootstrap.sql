-- Greenfield DB provisioning for theMetaCity (Postgres 18).
--
-- Alembic owns all TABLES (see tmc/migrations). This script owns everything
-- Alembic does not: schemas, the read/write roles, and the grants that make the
-- read-only engine safe. Run once against a fresh database, then `flask db
-- upgrade` creates the tables.
--
-- Role passwords are injected by the container's secrets step (not stored here).
-- Roles:
--   tmc_master   -> the `default` (read/write) engine; owns the schemas/tables.
--   tmc_selector -> the `read_only` engine; USAGE + SELECT only.

-- Schemas (owned by the write role) + the Alembic version schema.
CREATE SCHEMA IF NOT EXISTS com                AUTHORIZATION tmc_master;
CREATE SCHEMA IF NOT EXISTS media              AUTHORIZATION tmc_master;
CREATE SCHEMA IF NOT EXISTS everyday_ordinary  AUTHORIZATION tmc_master;
CREATE SCHEMA IF NOT EXISTS alembic            AUTHORIZATION tmc_master;

-- Read-only role: may enter the schemas and read.
GRANT USAGE ON SCHEMA com, media, everyday_ordinary TO tmc_selector;

-- Tables Alembic creates (as tmc_master) must be SELECT-able by the read role.
ALTER DEFAULT PRIVILEGES FOR ROLE tmc_master IN SCHEMA com, media, everyday_ordinary
    GRANT SELECT ON TABLES TO tmc_selector;

-- Postgres 18 provides uuidv7() and uuid_extract_timestamp() natively, so no
-- custom functions schema is needed (the models reference the built-ins).
