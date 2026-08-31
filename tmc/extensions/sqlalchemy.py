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


def preflight(app: Flask) -> list[str]:
    errors: list[str] = []
    engines = app.config.get("SQLALCHEMY_ENGINES")
    if not engines:
        errors.append("SQLALCHEMY_ENGINES not configured")
    else:
        errors.extend(f"SQLALCHEMY_ENGINES missing '{name}' engine" for name in ("default", "read_only") if name not in engines)
    return errors


def init_app(app: Flask) -> None:
    """Bind the extension and register read-session teardown."""
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
    """Populate SQLALCHEMY_ENGINES from the environment (non-injected path)."""
    from tmc.extensions.database import engines_from_env

    app.config["SQLALCHEMY_ENGINES"] = engines_from_env()
