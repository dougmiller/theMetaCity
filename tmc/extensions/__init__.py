import sys

from tmc.extensions import caching, config, debug_toolbar, sqlalchemy
from tmc.extensions.caching import cache
from tmc.extensions.configs import configs
from tmc.extensions.handlers import handlers as handlers
from tmc.extensions.jinja_filters import register_filters
from tmc.extensions.markdown import md
from tmc.extensions.sqlalchemy import Base, db, read_session

_REGISTRY = (caching, config, debug_toolbar, sqlalchemy)


def preflight(app) -> None:
    """Aggregate preflight errors across every registered component.
    Aborts the app if any of the components fail."""
    errors_list: list[str] = []
    for component in _REGISTRY:
        errors_list.extend(component.preflight(app))
    if errors_list:
        sys.exit("Startup failed:\n" + "\n".join(f"  - {e}" for e in errors_list))


def init_app(app) -> None:
    """Sets up the components for the app.
    Preflight checks have been performed already, so get on with the app."""

    for component in _REGISTRY:
        component.init_app(app)


__all__ = (
    "Base",
    "cache",
    "configs",
    "db",
    "debug_toolbar",
    "handlers",
    "md",
    "read_session",
    "register_filters",
)
