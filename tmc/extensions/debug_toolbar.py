"""Flask-DebugToolbar (dev-only, optional `debug` extra).

Flask-DebugToolbar's built-in SQLAlchemy panel reads Flask-SQLAlchemy's
``get_debug_queries()``, which Flask-SQLAlchemy-Lite does not provide — so the
panel shows nothing. We swap it for ``flask_debugtoolbar_sqlalchemy``'s panel,
which records queries via SQLAlchemy engine events and works with the lite
extension. Kept here (not in the sqlalchemy extension) because it is a toolbar
concern; nothing else needs to be ordered around it.
"""

import importlib.util

from flask import Flask

_TRUTHY = {"1", "true", "yes", "on"}
_BUILTIN_SQLA_PANEL = "flask_debugtoolbar.panels.sqlalchemy.SQLAlchemyDebugPanel"
_LITE_SQLA_PANEL = "flask_debugtoolbar_sqlalchemy.SQLAlchemyPanel"


def _debug_enabled(app: Flask) -> bool:
    return str(app.config.get("FLASK_DEBUG") or "").strip().lower() in _TRUTHY


def _swap_sqlalchemy_panel(app: Flask) -> None:
    """Replace the built-in SQLAlchemy panel with the lite-compatible one.

    Defensive about position and version drift: replaces in place if the
    built-in panel is present, otherwise appends; no-op (leaving the built-in)
    if the replacement package isn't installed, and never duplicates.
    """
    if importlib.util.find_spec("flask_debugtoolbar_sqlalchemy") is None:
        return
    panels = list(app.config.get("DEBUG_TB_PANELS", ()))
    if _LITE_SQLA_PANEL in panels:
        return
    if _BUILTIN_SQLA_PANEL in panels:
        panels[panels.index(_BUILTIN_SQLA_PANEL)] = _LITE_SQLA_PANEL
    else:
        panels.append(_LITE_SQLA_PANEL)
    app.config["DEBUG_TB_PANELS"] = tuple(panels)


def init_app(app: Flask) -> None:
    # Dev-only aid, shipped in the optional `debug` extra. Never required for
    # boot: skip unless FLASK_DEBUG is on AND the package is installed (it isn't
    # in the production image). Import is deferred so importing this module
    # never depends on the extra being present.
    if not _debug_enabled(app):
        return
    if importlib.util.find_spec("flask_debugtoolbar") is None:
        return

    from flask_debugtoolbar import DebugToolbarExtension

    DebugToolbarExtension(app)  # populates DEBUG_TB_PANELS defaults
    _swap_sqlalchemy_panel(app)  # then swap the SQLAlchemy panel in place


def preflight(app: Flask) -> list[str]:
    # SECRET_KEY (required by the toolbar) is preflighted by the app-general
    # config, which runs first in the registry.
    return []
