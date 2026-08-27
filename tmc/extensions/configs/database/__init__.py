from typing import ClassVar

from tmc.extensions.configs.database.connectors import PSQLDatabaseConfig, SQLiteDatabaseConfig


class DatabaseConfig:
    """Builds the SQLALCHEMY_ENGINES mapping for Flask-SQLAlchemy-Lite.

    Two named engines:
      * ``default``   — read/write (admin role)
      * ``read_only`` — read-only (selector role)

    Both are read from dotted config keys, e.g. ``default.hostname``,
    ``read_only.user`` (see ``.env.database.example``).
    """

    REQUIRED_ENGINE_NAMES: ClassVar[list[str]] = [
        "default",
        "read_only",
    ]

    def __init__(self) -> None:
        pass

    def get_dict_of_engines(self, raw_config: dict) -> dict:
        """Return ``{engine_name: sqlalchemy_url}`` for Flask-SQLAlchemy-Lite."""
        engines = {}

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
