#!/bin/sh
POSTGRES="psql --username ${POSTGRES_USER}"

echo "Creating FUNCTIONS schema"
echo "======"

$POSTGRES <<-SQL
  \c themetacity;
  SET ROLE ${TMC_MASTER_USER};
  CREATE SCHEMA functions;
SQL

echo "======"

echo "======"
