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
echo "CREATING FUNCTION: functions.uuid_generate_v7()"
$POSTGRES <<-SQL
  \c themetacity;
  SET ROLE tmc_master;

  CREATE OR REPLACE FUNCTION functions.uuid_generate_v7()
  returns uuid
  as \$\$
  declare
    unix_ts_ms bytea;
    uuid_bytes bytea;
  begin
    unix_ts_ms = substring(int8send(floor(extract(epoch from clock_timestamp()) * 1000)::bigint) from 3);

    -- use random v4 uuid as starting point (which has the same variant we need)
    uuid_bytes = uuid_send(gen_random_uuid());

    -- overlay timestamp
    uuid_bytes = overlay(uuid_bytes placing unix_ts_ms from 1 for 6);

    -- set version 7
    uuid_bytes = set_byte(uuid_bytes, 6, (b'0111' || get_byte(uuid_bytes, 6)::bit(4))::bit(8)::int);

    return encode(uuid_bytes, 'hex')::uuid;
  end \$\$
  language plpgsql
  VOLATILE;
SQL

echo "CREATED FUNCTION: functions.uuid_generate_v7()"
echo "[*] Setting permissions for functions"
$POSTGRES <<-SQL
  \c themetacity;
  SET ROLE tmc_master;
  GRANT USAGE ON SCHEMA functions TO ${COM_ADMIN_USER};
  GRANT USAGE ON SCHEMA functions TO ${MEDIA_ADMIN_USER};
  GRANT USAGE ON SCHEMA functions TO ${EDO_ADMIN_USER};

  GRANT EXECUTE ON FUNCTION functions.uuid_generate_v7() TO ${COM_ADMIN_USER};
  GRANT EXECUTE ON FUNCTION functions.uuid_generate_v7() TO ${MEDIA_ADMIN_USER};
  GRANT EXECUTE ON FUNCTION functions.uuid_generate_v7() TO ${EDO_ADMIN_USER};
SQL

echo "======"
