import sys

from flask import Flask

from tmc.extensions import boto, caching, config, debug_toolbar, logging, markdown, sqlalchemy
from tmc.extensions.caching import cache
from tmc.extensions.handlers import handlers as handlers
from tmc.extensions.jinja_filters import register_filters
from tmc.extensions.sqlalchemy import Base, db, read_session

# App-general logging first, then extensions in initialisation order.
_REGISTRY = (logging, config, sqlalchemy, caching, boto, debug_toolbar, markdown)


def load_config(app: Flask) -> None:
    """Populate app.config from the environment for every component that
    sources its own config. Skipped when config is injected (tests)."""
    for component in _REGISTRY:
        loader = getattr(component, "load_config", None)
        if loader is not None:
            loader(app)


def preflight(app: Flask) -> None:
    """Aggregate preflight errors across every registered component (do not stop on the first error).
    Some components do not preflight.
    Aborts the app if any component fails."""
    errors_list: list[str] = []
    for component in _REGISTRY:
        _preflight = getattr(component, "preflight", None)
        if _preflight is not None:
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
    "handlers",
    "load_config",
    "md",
    "read_session",
    "register_filters",
)
