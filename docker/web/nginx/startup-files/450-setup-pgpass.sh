#!/bin/bash

mkdir -p /var/www/

PGPASSFILE=/var/www/.pgpass

#!/bin/bash
echo "Writing .pgpass"
echo "======"

rm $PGPASSFILE
touch $PGPASSFILE

echo "postgres:5432:themetacity:$TMC_MASTER_USER:$TMC_MASTER_USER_PASSWORD" >> $PGPASSFILE
echo "postgres:5432:themetacity:$TMC_SELECT_USER:$TMC_SELECT_USER_PASSWORD" >> $PGPASSFILE
echo "postgres:5432:themetacity:$COM_ADMIN_USER:$COM_ADMIN_USER_PASSWORD" >> $PGPASSFILE
echo "postgres:5432:themetacity:$COM_SELECT_USER:$COM_SELECT_USER_PASSWORD" >> $PGPASSFILE
echo "postgres:5432:themetacity:$MEDIA_ADMIN_USER:$MEDIA_ADMIN_USER_PASSWORD" >> $PGPASSFILE
echo "postgres:5432:themetacity:$MEDIA_SELECT_USER:$MEDIA_SELECT_USER_PASSWORD" >> $PGPASSFILE
echo "postgres:5432:themetacity:$EDO_ADMIN_USER:$EDO_ADMIN_USER_PASSWORD" >> $PGPASSFILE
echo "postgres:5432:themetacity:$EDO_SELECT_USER:$EDO_SELECT_USER_PASSWORD" >> $PGPASSFILE

chown www-data:www-data $PGPASSFILE
chmod 600 $PGPASSFILE

echo "======"
echo "Finished .pgpass"

