# theMetaCity Flask

The Meta City website — a multi-subdomain Flask application (home / blog / media /
api / everydayordinary) backed by PostgreSQL.

## Development

    uv sync --group dev
    uv run flask --app theMetaCity.py run

## Tests

    uv run pytest                 # offline tests (no database)
    TMC_TEST_DATABASE_URL=postgresql+psycopg://user:pw@host:5432/tmc_test uv run pytest

See `docs/upgrade/` for the modernization baseline.
