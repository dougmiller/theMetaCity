#!/bin/sh
POSTGRES="psql --username ${POSTGRES_USER}"

echo "Creating everyday_ordinary schema"
echo "======"

$POSTGRES <<-SQL
  \c themetacity;
  SET ROLE ${TMC_MASTER_USER};
  CREATE SCHEMA everyday_ordinary;
  GRANT CONNECT ON DATABASE themetacity TO ${EDO_ADMIN_USER};
  ALTER SCHEMA everyday_ordinary OWNER TO ${EDO_ADMIN_USER};
  GRANT USAGE ON SCHEMA everyday_ordinary TO ${EDO_SELECT_USER};

  ALTER DEFAULT PRIVILEGES
  FOR USER ${EDO_ADMIN_USER}
  IN SCHEMA everyday_ordinary
    GRANT SELECT ON
    TABLES TO ${EDO_SELECT_USER};
SQL

echo "======"
echo "Setting up EDO tables"
$POSTGRES <<-SQL
  \c themetacity;
  SET ROLE ${EDO_ADMIN_USER};
  CREATE TABLE everyday_ordinary.everyday_ordinary (
    id uuid NOT NULL DEFAULT uuidv7(),
    content varchar,
    created_at timestamp DEFAULT (now() AT TIME ZONE 'utc'),
    updated_at timestamp DEFAULT (now() AT TIME ZONE 'utc'),
    deleted_at timestamp DEFAULT null
  );
  ALTER TABLE ONLY everyday_ordinary.everyday_ordinary ADD CONSTRAINT everyday_ordinary_pkey PRIMARY KEY (id);

SQL