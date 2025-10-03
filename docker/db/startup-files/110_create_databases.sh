#!/bin/sh
POSTGRES="psql --username ${POSTGRES_USER}"

echo "CREATING the DATABASE: themetacity"
echo "======"

$POSTGRES <<-SQL
  CREATE DATABASE themetacity;
  ALTER DATABASE themetacity OWNER TO ${TMC_MASTER_USER};
SQL
echo "[*] CREATED the DATABASE: themetacity"
echo "======"
