# Migrations (Flask-Alembic)

Config-driven (no `env.py`). The ORM metadata (`Base.metadata`) is the single
source of truth; see `tmc/extensions/alembic.py`.

## Prerequisites
The database, schemas (`com`, `media`, `everyday_ordinary`), the `alembic`
version schema, and roles/grants are created by the DB init SQL
(`docker/db/startup-files/`). Postgres 18 provides `uuidv7()` and
`uuid_extract_timestamp()` natively (used by the models' defaults / generated
columns).

## Generate the baseline (one-off, on an empty PG18 with the schemas present)

    FLASK_APP=theMetaCity.py flask db revision "baseline schema"

This autogenerates one revision from the models (all tables, `uuidv7()` id
defaults, `uuid_extract_timestamp(id)` generated timestamps). Verified to apply
cleanly on an empty database.

## Apply

    flask db upgrade      # run outstanding migrations
    flask db current      # show applied revision
    flask db revision "msg"   # autogenerate a new revision after model changes
