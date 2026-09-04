"""Unit tests for the database connectors' self-preflight and URL building.

These exercise config-shape validation and the .pgpass password resolution
(mocked) without touching a real database — they run regardless of
TMC_TEST_DATABASE_URL.
"""

import pgpasslib
import pytest

from tmc.extensions.database import DatabaseConfig
from tmc.extensions.database.connectors import PSQLDatabaseConfig, SQLiteDatabaseConfig

_FULL_PG = {"hostname": "db.host", "name": "themetacity", "user": "tmc_master"}


def _pg(**overrides: str) -> PSQLDatabaseConfig:
    fields = {**_FULL_PG, **overrides}
    return PSQLDatabaseConfig(
        host=fields.get("hostname", ""),
        port=fields.get("port", ""),
        name=fields.get("name", ""),
        user=fields.get("user", ""),
    )


# --- Postgres connector ------------------------------------------------------


def test_psql_port_defaults_to_5432() -> None:
    assert _pg().port == "5432"


def test_psql_explicit_port_kept() -> None:
    assert _pg(port="6543").port == "6543"


def test_psql_missing_identity_fields_reported() -> None:
    errors = PSQLDatabaseConfig().preflight()
    assert "postgres hostname not set" in errors
    assert "postgres database name not set" in errors
    assert "postgres user not set" in errors


def test_psql_invalid_port_reported() -> None:
    errors = _pg(port="not-a-port").preflight()
    assert any("not a valid integer" in e for e in errors)


def test_psql_missing_password_reported(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(pgpasslib, "getpass", lambda *_: None)
    errors = _pg().preflight()
    assert any("no .pgpass password" in e for e in errors)


def test_psql_pgpass_file_not_found_reported(monkeypatch: pytest.MonkeyPatch) -> None:
    def _raise(*_: object) -> str:
        raise pgpasslib.FileNotFound

    monkeypatch.setattr(pgpasslib, "getpass", _raise)
    errors = _pg().preflight()
    assert any(".pgpass file not found" in e for e in errors)


def test_psql_valid_config_passes_and_builds_uri(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(pgpasslib, "getpass", lambda *_: "p@ss word")
    conn = _pg()
    assert conn.preflight() == []
    # Password is URL-quoted in the URI.
    assert conn.database_uri == "postgresql+psycopg://tmc_master:p%40ss+word@db.host:5432/themetacity"


def test_psql_skips_pgpass_when_identity_missing(monkeypatch: pytest.MonkeyPatch) -> None:
    called = False

    def _spy(*_: object) -> str:
        nonlocal called
        called = True
        return "pw"

    monkeypatch.setattr(pgpasslib, "getpass", _spy)
    PSQLDatabaseConfig(host="", name="", user="").preflight()
    assert called is False


# --- SQLite connector --------------------------------------------------------


def test_sqlite_missing_path_reported() -> None:
    assert SQLiteDatabaseConfig().preflight() == ["sqlite path not set"]


def test_sqlite_valid_path_builds_uri() -> None:
    conn = SQLiteDatabaseConfig(path="/var/data/tmc.db")
    assert conn.preflight() == []
    assert conn.database_uri == "sqlite:////var/data/tmc.db"


# --- DatabaseConfig aggregation ---------------------------------------------


def test_databaseconfig_prefixes_errors_with_engine_name() -> None:
    errors = DatabaseConfig({}).preflight()
    assert any(e.startswith("engine 'default': postgres hostname not set") for e in errors)
    assert any(e.startswith("engine 'read_only': postgres user not set") for e in errors)


def test_databaseconfig_reports_unsupported_type() -> None:
    raw = {"default.type": "mysql", "read_only.type": "mysql"}
    errors = DatabaseConfig(raw).preflight()
    assert errors == [
        "engine 'default': unsupported database type 'mysql'",
        "engine 'read_only': unsupported database type 'mysql'",
    ]


def test_databaseconfig_sqlite_engines_build_end_to_end() -> None:
    raw = {
        "default.type": "sqlite",
        "default.path": "/tmp/write.db",
        "read_only.type": "sqlite",
        "read_only.path": "/tmp/read.db",
    }
    cfg = DatabaseConfig(raw)
    assert cfg.preflight() == []
    assert cfg.get_dict_of_engines() == {
        "default": "sqlite:////tmp/write.db",
        "read_only": "sqlite:////tmp/read.db",
    }
