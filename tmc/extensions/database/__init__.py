"""Database engine configuration — owned by the SQLAlchemy extension.

Builds the ``SQLALCHEMY_ENGINES`` mapping (Flask-SQLAlchemy-Lite) for the
``default`` (read/write) and ``read_only`` engines from the merged environment.

Each engine delegates to a connector (Postgres or SQLite) that validates its
own config and applies its own structural defaults. ``DatabaseConfig`` builds
the connectors from the raw env, aggregates their ``preflight`` errors under
the engine name, and — only once preflight has passed — resolves each engine's
URL. Passwords are sourced from ``.pgpass`` via the Postgres connector, never
from config files.
"""

from typing import ClassVar, Protocol

from tmc.extensions._env import raw_env
from tmc.extensions.database.connectors import PSQLDatabaseConfig, SQLiteDatabaseConfig

# Structural default: which connector an engine uses when unspecified.
_DEFAULT_ENGINE_TYPE = "postgres"


class _Connector(Protocol):
    """Common shape every connector implements."""

    def preflight(self) -> list[str]: ...

    @property
    def database_uri(self) -> str: ...


class _UnsupportedConnector:
    """Stand-in for an engine whose ``.type`` is unknown.

    Surfaces the problem through ``preflight`` (like every other config error)
    instead of raising at construction time.
    """

    def __init__(self, engine_name: str, conn_type: str) -> None:
        self.engine_name = engine_name
        self.conn_type = conn_type

    def preflight(self) -> list[str]:
        return [f"unsupported database type '{self.conn_type}'"]

    @property
    def database_uri(self) -> str:
        raise RuntimeError(f"engine '{self.engine_name}' has unsupported type '{self.conn_type}'")


class DatabaseConfig:
    REQUIRED_ENGINE_NAMES: ClassVar[list[str]] = [
        "default",
        "read_only",
    ]

    def __init__(self, raw_config: dict[str, str | None]) -> None:
        self._raw = raw_config
        self.connectors: dict[str, _Connector] = {name: self._connector_for(name) for name in self.REQUIRED_ENGINE_NAMES}

    def _connector_for(self, engine_name: str) -> _Connector:
        conn_type = self._raw.get(f"{engine_name}.type") or _DEFAULT_ENGINE_TYPE

        if conn_type == "postgres":
            return PSQLDatabaseConfig(
                host=self._raw.get(f"{engine_name}.hostname") or "",
                port=self._raw.get(f"{engine_name}.port") or "",
                name=self._raw.get(f"{engine_name}.name") or "",
                user=self._raw.get(f"{engine_name}.user") or "",
            )
        if conn_type == "sqlite":
            return SQLiteDatabaseConfig(path=self._raw.get(f"{engine_name}.path") or "")
        return _UnsupportedConnector(engine_name, conn_type)

    def preflight(self) -> list[str]:
        """Aggregate every engine's connector errors, tagged with the engine name."""
        errors: list[str] = []
        for engine_name, connector in self.connectors.items():
            errors.extend(f"engine '{engine_name}': {e}" for e in connector.preflight())
        return errors

    def get_dict_of_engines(self) -> dict[str, str]:
        """Return ``{engine_name: sqlalchemy_url}``. Call only after preflight passes."""
        return {name: connector.database_uri for name, connector in self.connectors.items()}


def database_config_from_env() -> DatabaseConfig:
    """Build the database config (connectors only, no .pgpass read) from the env."""
    return DatabaseConfig(raw_env())
