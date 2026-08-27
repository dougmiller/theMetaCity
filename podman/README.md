# Container stack (podman)

Postgres 18 + Flask (gunicorn) + nginx, run with `podman-compose`.

## First run

1. Create the app config from the examples (git-ignored):
   - `.env.basic` (SERVER_NAME, SECRET_KEY, DEBUG, CSRF_ENABLED, *_PATH)
   - `.env.database` — copy from `.env.database.example` (points `default`/`read_only` at the `postgres` service).
2. Create the DB role passwords (git-ignored) from the examples:
   - `podman/postgres/secrets/{postgres,tmc_master,tmc_selector}_password.txt`
3. `make up` (build + start), then browse http://localhost:8000

## What happens on start
- Postgres init scripts create the `tmc_master` (read/write) and `tmc_selector`
  (read-only) roles, the `com`/`media`/`everyday_ordinary`/`alembic` schemas, and
  the read-only grants (Alembic owns the tables).
- The flask entrypoint waits for Postgres, writes a `.pgpass` from the secrets,
  runs `flask db upgrade`, then starts gunicorn (`theMetaCity:application`).

Note: Postgres 18 provides `uuidv7()` / `uuid_extract_timestamp()` natively — no
custom functions needed.
