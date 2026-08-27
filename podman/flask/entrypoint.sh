#!/bin/bash
set -e
echo "Starting theMetaCity..."

echo "Waiting for database (postgres:5432)..."
while ! nc -z postgres 5432; do sleep 1; done
echo "Database is up."

# Build a .pgpass from the mounted secrets so pgpasslib finds the passwords.
cat > "$PGPASSFILE" <<PG
postgres:5432:themetacity:tmc_master:$(cat /run/secrets/tmc_master_password)
postgres:5432:themetacity:tmc_selector:$(cat /run/secrets/tmc_selector_password)
PG
chmod 600 "$PGPASSFILE"

echo "Running migrations (flask db upgrade)..."
uv run flask db upgrade

WORKERS=${GUNICORN_WORKERS:-$(( 2 * $(nproc) + 1 ))}
echo "Starting Gunicorn with $WORKERS workers..."
exec uv run gunicorn -c gunicorn.conf.py --workers "$WORKERS" "theMetaCity:application"
