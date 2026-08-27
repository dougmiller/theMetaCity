#!/bin/bash
set -e
# Create the two application roles from mounted secrets.
#   tmc_master   -> the `default` (read/write) engine
#   tmc_selector -> the `read_only` engine
ADMIN_PW=$(cat /run/secrets/tmc_master_password)
SELECTOR_PW=$(cat /run/secrets/tmc_selector_password)

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<SQL
    CREATE USER tmc_master   WITH LOGIN PASSWORD '${ADMIN_PW}';
    CREATE USER tmc_selector WITH LOGIN PASSWORD '${SELECTOR_PW}';
    GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO tmc_master, tmc_selector;
    ALTER DATABASE ${POSTGRES_DB} OWNER TO tmc_master;
SQL
echo "Roles tmc_master / tmc_selector created."
