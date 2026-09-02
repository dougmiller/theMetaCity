import sys

from flask import Flask

from tmc.extensions import alembic, boto, caching, config, debug_toolbar, handlers, jinja_filters, logging, marshmallow, sqlalchemy, tmc_markdown
from tmc.extensions.caching import cache
from tmc.extensions.sqlalchemy import Base, db, read_session

# App-general logging first, then extensions in initialisation order.
_REGISTRY = (
    logging,
    config,
    alembic,
    sqlalchemy,
    caching,
    boto,
    tmc_markdown,
    marshmallow,
    debug_toolbar,
    handlers,
    jinja_filters
)


def load_config(app: Flask) -> None:
    """Populate app.config from the environment for every component that
    sources its own config. Skipped when config is injected (tests)."""
    for component in _REGISTRY:
        loader = getattr(component, "load_config", None)
        if loader is not None: # The component may not have a load_config method. Skip if so.
            loader(app)


def preflight(app: Flask) -> None:
    """Aggregate preflight errors across every registered component (do not stop on the first error).
    Some components do not preflight.
    Aborts the app if any component fails."""
    errors_list: list[str] = []
    for component in _REGISTRY:
        _preflight = getattr(component, "preflight", None)
        if _preflight is not None: # The component may not have a preflight method. Skip if so.
            errors_list.extend(_preflight(app))
    if errors_list:
        sys.exit("Startup failed:\n" + "\n".join(f"  - {e}" for e in errors_list))


def init_app(app: Flask) -> None:
    """Preflight has already passed; initialise each component in order."""
    for component in _REGISTRY:
        component.init_app(app)


__all__ = (
    "Base",
    "cache",
    "db",
    "load_config",
    "read_session",
    "register_filters",
)
