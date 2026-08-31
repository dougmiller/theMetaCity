"""Database engine configuration — owned by the SQLAlchemy extension.

Builds the ``SQLALCHEMY_ENGINES`` mapping (Flask-SQLAlchemy-Lite) for the
``default`` (read/write) and ``read_only`` engines from the merged
environment. Passwords are sourced from ``.pgpass`` via the connectors,
never from config files.
"""

from typing import ClassVar

from tmc.extensions._env import raw_env
from tmc.extensions.database.connectors import PSQLDatabaseConfig, SQLiteDatabaseConfig


class DatabaseConfig:
    REQUIRED_ENGINE_NAMES: ClassVar[list[str]] = [
        "default",
        "read_only",
    ]

    def get_dict_of_engines(self, raw_config: dict) -> dict:
        """Return ``{engine_name: sqlalchemy_url}`` for Flask-SQLAlchemy-Lite."""
        engines: dict[str, str] = {}

        for engine_name in self.REQUIRED_ENGINE_NAMES:
            conn_type = raw_config.get(engine_name + ".type", "postgres")

            if conn_type == "postgres":
                engines[engine_name] = PSQLDatabaseConfig(
                    host=raw_config.get(engine_name + ".hostname", ""),
                    port=raw_config.get(engine_name + ".port", "5432"),
                    name=raw_config.get(engine_name + ".name", ""),
                    user=raw_config.get(engine_name + ".user", ""),
                ).DATABASE_URI
            elif conn_type == "sqlite":
                engines[engine_name] = SQLiteDatabaseConfig(path=raw_config.get(engine_name + ".path", "")).DATABASE_URI
            else:
                raise ValueError(f"Unsupported database type '{conn_type}' for engine '{engine_name}'")

        return engines


def engines_from_env() -> dict:
    """Build the engine map from the merged environment."""
    return DatabaseConfig().get_dict_of_engines(raw_env())
