#!/bin/bash

echo "Writing .pgpass"
echo "======"

touch /var/lib/postgresql/.pgpass

echo "localhost:5433:themetacity:$TMC_MASTER_USER:$TMC_MASTER_USER_PASSWORD" >> /var/lib/postgresql/.pgpass
echo "localhost:5433:themetacity:$TMC_ADMIN_USER:$TMC_ADMIN_USER_PASSWORD" >> /var/lib/postgresql/.pgpass
echo "localhost:5433:themetacity:$MEDIA_ADMIN_USER:$MEDIA_ADMIN_USER_PASSWORD" >> /var/lib/postgresql/.pgpass
echo "localhost:5433:themetacity:$TMC_SELECT_USER:$TMC_SELECT_USER_PASSWORD" >> /var/lib/postgresql/.pgpass
echo "localhost:5433:themetacity:$EDO_ADMIN_USER:$EDO_ADMIN_USER_PASSWORD" >> /var/lib/postgresql/.pgpass
echo "localhost:5433:themetacity:$EDO_SELECT_USER:$EDO_SELECT_USER_PASSWORD" >> /var/lib/postgresql/.pgpass

echo "======"
echo "Finished .pgpass"
