"""Pytest fixtures for theMetaCityFlask (Flask-SQLAlchemy-Lite).

Offline tests build the app with a dummy engine config (no connection).
DB-backed tests need a blank PostgreSQL; provide its URL via
``TMC_TEST_DATABASE_URL`` and they self-provision the schema. Both the
``default`` (write) and ``read_only`` engines point at that one test database.

    TMC_TEST_DATABASE_URL=postgresql+psycopg://user:pw@host:5432/tmc_test uv run pytest
"""

import os
from collections.abc import Iterator

import pytest
import sqlalchemy as sa
from flask import Flask
from flask.testing import FlaskClient
from sqlalchemy import text
from sqlalchemy.orm import Session

from tmc import create_app
from tmc.extensions import Base, db

TEST_DB_URL = os.environ.get("TMC_TEST_DATABASE_URL")
ENGINE_NAMES = ("default", "read_only")
SCHEMAS = ("com", "media", "everyday_ordinary")

# PG18-native function shims for older Postgres used in testing (inert on PG18,
# where the pg_catalog built-ins take precedence over these public-schema ones).
_UUIDV7_SHIM = """
CREATE OR REPLACE FUNCTION uuidv7() RETURNS uuid LANGUAGE sql VOLATILE AS $fn$
    SELECT encode(
        overlay(uuid_send(gen_random_uuid())
                placing substring(int8send(floor(extract(epoch FROM clock_timestamp()) * 1000)::bigint) FROM 3)
                FROM 1 FOR 6),
        'hex')::uuid
$fn$
"""
_UUID_EXTRACT_TS_SHIM = """
CREATE OR REPLACE FUNCTION uuid_extract_timestamp(u uuid) RETURNS timestamptz LANGUAGE sql IMMUTABLE AS $fn$
    SELECT to_timestamp((('x' || substr(replace(u::text, '-', ''), 1, 12))::bit(48)::bigint) / 1000.0)
$fn$
"""
OFFLINE_DB_URL = "postgresql+psycopg://tmc:tmc@localhost:5432/tmc_offline"


def _config(db_url) -> dict:
    return {
        "TESTING": True,
        "SECRET_KEY": "test-secret",
        "SERVER_NAME": "themetacity.test",
        "DEBUG": False,
        "CSRF_ENABLED": False,
        "EDO_UPLOAD_PATH": "/tmp/tmc-test-uploads",
        "ASSETS_PATH": "/tmp/tmc-test-assets",
        "DOCUMENTS_FOLDER_PATH": "/tmp/tmc-test-docs",
        "S3_BUCKET_NAME": "test-bucket",
        "S3_ACCESS_KEY": "test-access-key",
        "S3_SECRET_KEY": "test-secret-key",
        "S3_ENDPOINT_URL": "https://s3.test.invalid",
        "S3_REGION_NAME": "us-east-1",
        "SQLALCHEMY_ENGINES": dict.fromkeys(ENGINE_NAMES, db_url),
    }


def _database_available() -> bool:
    if not TEST_DB_URL:
        return False
    try:
        engine = sa.create_engine(TEST_DB_URL)
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        engine.dispose()
    except Exception:
        return False
    return True


DB_AVAILABLE = _database_available()

requires_db = pytest.mark.skipif(
    not DB_AVAILABLE,
    reason="Set TMC_TEST_DATABASE_URL to a reachable Postgres to run DB-backed tests.",
)


@pytest.fixture(scope="session")
def app_offline() -> Flask:
    """App built with a dummy engine config. Engines are lazy — no connection."""
    return create_app(_config(OFFLINE_DB_URL))


@pytest.fixture()
def client_offline(app_offline) -> FlaskClient:
    return app_offline.test_client()


def _load_all_models() -> None:
    import importlib
    import pkgutil

    import tmc.models as models_pkg

    for mod in pkgutil.walk_packages(models_pkg.__path__, models_pkg.__name__ + "."):
        importlib.import_module(mod.name)


def _provision_schema() -> None:
    """Make a blank Postgres able to hold the ORM metadata, then create tables.

    Installs uuidv7()/uuid_extract_timestamp() shims first so the models'
    server_default/Computed DDL resolves on Postgres versions without the PG18
    built-ins.
    """
    engine = db.engines["default"]
    with engine.begin() as conn:
        for schema in SCHEMAS:
            conn.execute(text(f'CREATE SCHEMA IF NOT EXISTS "{schema}"'))
        conn.execute(text(_UUIDV7_SHIM))
        conn.execute(text(_UUID_EXTRACT_TS_SHIM))
    _load_all_models()
    Base.metadata.create_all(engine)


def _app_table_names() -> list[str]:
    return [f'"{t.schema}"."{t.name}"' for t in Base.metadata.sorted_tables if t.schema in SCHEMAS]


@pytest.fixture(scope="session")
def app() -> Flask:
    if not DB_AVAILABLE:
        pytest.skip("No reachable TMC_TEST_DATABASE_URL")
    application = create_app(_config(TEST_DB_URL))
    # api/media/edo blueprints are on subdomains; enable matching for the client.
    application.subdomain_matching = True
    with application.app_context():
        _provision_schema()
    return application


@pytest.fixture()
def client(app) -> FlaskClient:
    return app.test_client()


@pytest.fixture()
def db_session(app) -> Iterator[Session]:
    """Function-scoped write session; truncates all app tables after each test.

    The test client reuses this outer app context, so ``teardown_appcontext``
    doesn't fire per request — close both sessions explicitly before TRUNCATE so
    no lingering AccessShareLock blocks it.
    """
    from flask import g

    with app.app_context():
        yield db.session
        db.session.rollback()
        db.session.close()
        read = g.pop("_read_session", None)
        if read is not None:
            read.close()
        names = _app_table_names()
        if names:
            with db.engines["default"].begin() as conn:
                conn.execute(text(f"TRUNCATE {', '.join(names)} RESTART IDENTITY CASCADE"))
