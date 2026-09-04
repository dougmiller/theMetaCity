"""PostgreSQL connector — config validation and URL construction.

The connector owns its own defaults and validation. ``preflight`` checks the
config *shape* (identity fields present, port numeric) and resolves the
password from ``.pgpass`` (a missing password is a genuine boot-time
misconfiguration), returning a list of error strings — it never aborts the
process. The aggregating startup preflight collects those alongside every
other component's errors and exits once. ``database_uri`` builds the SQLAlchemy
URL and is only called after preflight has passed.

Structural fields get sensible defaults (``port`` -> 5432); identity fields
(host, name, user) are never defaulted — a missing one is reported so the app
fails loudly instead of booting toward the wrong place.
"""

from urllib.parse import quote_plus

_DEFAULT_PORT = "5432"


class PSQLDatabaseConfig:
    def __init__(self, host: str = "", port: str = "", name: str = "", user: str = "") -> None:
        self.host = host
        self.port = port or _DEFAULT_PORT  # structural default
        self.name = name
        self.user = user
        self.password: str | None = None

    def preflight(self) -> list[str]:
        """Validate config shape and resolve the .pgpass password.

        Returns an empty list when the engine is ready to build a URL.
        """
        errors: list[str] = []

        # Identity fields: required, never defaulted.
        if not self.host:
            errors.append("postgres hostname not set")
        if not self.name:
            errors.append("postgres database name not set")
        if not self.user:
            errors.append("postgres user not set")

        # Structural field: must be an integer (default already applied).
        try:
            int(self.port)
        except ValueError:
            errors.append(f"postgres port '{self.port}' is not a valid integer")

        # Only reach for .pgpass once the connection coordinates are sane.
        if not errors:
            errors.extend(self._resolve_password())

        return errors

    def _resolve_password(self) -> list[str]:
        """Look the password up in ``.pgpass``; cache it on success.

        Returns error strings instead of exiting so preflight can aggregate.
        """
        import pgpasslib

        try:
            password = pgpasslib.getpass(self.host, int(self.port), self.name, self.user)
        except pgpasslib.FileNotFound:
            return [".pgpass file not found; create and populate it"]
        except pgpasslib.InvalidPermissions:
            return [".pgpass has invalid permissions (group- or world-readable bit set)"]
        except pgpasslib.InvalidEntry:
            return [".pgpass has an unreadable field"]
        except pgpasslib.PgPassException as ex:
            return [f".pgpass error: {ex}"]

        if password is None:
            return [f"no .pgpass password for {self.user}@{self.host}:{self.port}/{self.name}"]

        self.password = quote_plus(password)
        return []

    @property
    def database_uri(self) -> str:
        """SQLAlchemy URL. Preflight must have run and validated the config."""
        if self.password is None:
            # Preflight was bypassed; resolve now and fail loudly if we can't.
            errors = self._resolve_password()
            if errors:
                raise RuntimeError("; ".join(errors))
        return f"postgresql+psycopg://{self.user}:{self.password}@{self.host}:{self.port}/{self.name}"
