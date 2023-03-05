#!/bin/sh
POSTGRES="psql --username ${POSTGRES_USER}"

echo "Populating EDO"
echo "======"

$POSTGRES <<-SQL
  \c themetacity;
  SET ROLE ${EDO_ADMIN_USER};

SQL
echo "======"