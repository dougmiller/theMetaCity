#!/bin/sh
POSTGRES="psql --username ${POSTGRES_USER}"

echo "Creating COM schema and types"
echo "=== BEGIN ==="

$POSTGRES <<-SQL
  \c themetacity;
  SET ROLE ${TMC_MASTER_USER};
  CREATE SCHEMA com;
  GRANT CONNECT ON DATABASE themetacity TO ${COM_ADMIN_USER};
  GRANT USAGE ON SCHEMA com TO ${COM_SELECT_USER};
  ALTER SCHEMA com OWNER TO ${COM_ADMIN_USER};

  ALTER DEFAULT PRIVILEGES
  FOR USER ${COM_ADMIN_USER}
  IN SCHEMA com
    GRANT SELECT ON
    TABLES TO ${COM_SELECT_USER};

  CREATE TYPE com.variant AS ENUM ('blog','workshop');
SQL

echo "=== END ==="