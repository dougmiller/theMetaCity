"""SQLite connector — config validation and URL construction.

Mirrors the Postgres connector's contract: ``preflight`` validates the config
shape and returns error strings (never aborts), ``database_uri`` builds the
SQLAlchemy URL once preflight has passed. The database ``path`` is an identity
field, so it is required rather than defaulted — a missing path is reported.
"""


class SQLiteDatabaseConfig:
    def __init__(self, path: str = "") -> None:
        self.path = path

    def preflight(self) -> list[str]:
        if not self.path:
            return ["sqlite path not set"]
        return []

    @property
    def database_uri(self) -> str:
        return f"sqlite:///{self.path}"
