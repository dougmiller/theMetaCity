#!/bin/bash

echo "Writing HBA conf"
echo "======"

touch /data/postgres/pg_hba.conf

echo "# TYPE  DATABASE        USER                     ADDRESS                 METHOD" 			 >> /data/postgres/pg_hba.conf
echo "local   all             postgres                                         trust"  			 >> /data/postgres/pg_hba.conf
echo "host    all             postgres                 172.0.0.0/8             scram-sha-256"    >> /data/postgres/pg_hba.conf
echo "host    all             postgres                 192.168.0.0/16          scram-sha-256"    >> /data/postgres/pg_hba.conf
echo "host    themetacity     ${TMC_MASTER_USER}	   172.0.0.0/8             scram-sha-256"    >> /data/postgres/pg_hba.conf
echo "host    themetacity     ${COM_ADMIN_USER}	       172.0.0.0/8             scram-sha-256"    >> /data/postgres/pg_hba.conf
echo "host    themetacity     ${COM_SELECT_USER}	   172.0.0.0/8             scram-sha-256"    >> /data/postgres/pg_hba.conf
echo "host    themetacity     ${MEDIA_ADMIN_USER}      172.0.0.0/8             scram-sha-256"    >> /data/postgres/pg_hba.conf
echo "host    themetacity     ${MEDIA_SELECT_USER}     172.0.0.0/8             scram-sha-256"    >> /data/postgres/pg_hba.conf
echo "host    themetacity     ${TMC_SELECT_USER}       172.0.0.0/8             scram-sha-256"    >> /data/postgres/pg_hba.conf
echo "host    themetacity     ${EDO_ADMIN_USER}        172.0.0.0/8             scram-sha-256"    >> /data/postgres/pg_hba.conf
echo "host    themetacity     ${EDO_SELECT_USER}       172.0.0.0/8             scram-sha-256"    >> /data/postgres/pg_hba.conf

echo "======"
echo "Finished HBA conf"
