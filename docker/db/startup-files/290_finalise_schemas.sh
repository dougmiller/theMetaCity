#!/bin/sh
POSTGRES="psql --username ${POSTGRES_USER}"

echo "Finalising schemas"
echo "======"

$POSTGRES <<-SQL
  \c themetacity;
  SET ROLE ${TMC_MASTER_USER};
  ALTER DATABASE themetacity SET search_path = functions, com, media, everyday_ordinary;
  DROP SCHEMA public CASCADE;
SQL
echo "======"