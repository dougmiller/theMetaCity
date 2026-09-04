"""SQLAlchemy integration via Flask-SQLAlchemy-Lite.

Two engines are configured through ``SQLALCHEMY_ENGINES`` (see the configs
package):

* ``default``   — read/write, connects as the admin role.
* ``read_only`` — read-only, connects as the selector role.

``db.session`` uses the ``default`` (write) engine. Reads go through
``read_session()`` — a request-scoped session bound to the ``read_only`` engine,
so an accidental write on a read path is rejected by PostgreSQL, not just by
convention.
"""

from flask import Flask, g, has_app_context
from flask_sqlalchemy_lite import SQLAlchemy
from sqlalchemy.orm import DeclarativeBase, Session


class Base(DeclarativeBase):
    """Declarative base — Flask-SQLAlchemy-Lite does not provide one."""


# Alias used by model modules / migrations that want the metadata source.
Model = Base

db: SQLAlchemy = SQLAlchemy()

# app.extensions key holding the DatabaseConfig between load_config and
# init_app on the normal boot path. Absent on the injected (test) path,
# where SQLALCHEMY_ENGINES is supplied directly.
_DB_CONFIG_KEY = "tmc_database"


def preflight(app: Flask) -> list[str]:
    """Validate the database config.

    Normal boot path: each engine's connector validates its own config
    (identity fields present, port numeric, .pgpass password resolvable).
    Injected path (tests): SQLALCHEMY_ENGINES is supplied directly, so just
    confirm the required engines are present.
    """
    db_config = app.extensions.get(_DB_CONFIG_KEY)
    if db_config is not None:
        return db_config.preflight()

    engines = app.config.get("SQLALCHEMY_ENGINES")
    if not engines:
        return ["SQLALCHEMY_ENGINES not configured"]
    return [f"SQLALCHEMY_ENGINES missing '{name}' engine" for name in ("default", "read_only") if name not in engines]


def init_app(app: Flask) -> None:
    """Bind the extension and register read-session teardown.

    Preflight has passed, so on the normal boot path we now resolve each
    engine's URL (this is where the .pgpass lookup happens) and populate
    SQLALCHEMY_ENGINES. On the injected path it is already set.
    """
    db_config = app.extensions.get(_DB_CONFIG_KEY)
    if db_config is not None:
        app.config["SQLALCHEMY_ENGINES"] = db_config.get_dict_of_engines()

    db.init_app(app)

    @app.teardown_appcontext
    def _close_read_session(exc: BaseException | None = None) -> None:
        if not has_app_context():
            return
        session = g.pop("_read_session", None)
        if session is not None:
            session.close()


def read_session() -> Session:
    """Request-scoped session bound to the read-only engine.

    Created lazily and closed on app-context teardown, so objects it returns
    stay attached (lazy relationships resolve) for the whole request.
    """
    if "_read_session" not in g:
        g._read_session = Session(bind=db.engines["read_only"], expire_on_commit=False)
    return g._read_session


def load_config(app: Flask) -> None:
    """Build the database connectors from the environment (non-injected path).

    URLs are not resolved here: the .pgpass lookup is deferred to ``init_app``
    so that ``preflight`` can validate the config first and abort cleanly.
    """
    from tmc.extensions.database import database_config_from_env

    app.extensions[_DB_CONFIG_KEY] = database_config_from_env()
