import importlib.util

from flask import Flask


def _debug_enabled(app: Flask) -> bool:
    return str(app.config.get("FLASK_DEBUG") or "").strip().lower() in {"1", "true", "yes", "on"}


def init_app(app: Flask) -> None:
    # Dev-only aid, shipped in the optional `debug` extra. It must never be
    # required for boot: skip unless FLASK_DEBUG is on AND the package is
    # actually installed (it isn't in the production image). Import is deferred
    # so importing this module never depends on the extra being present.
    if not _debug_enabled(app):
        return
    if importlib.util.find_spec("flask_debugtoolbar") is None:
        return

    from flask_debugtoolbar import DebugToolbarExtension

    DebugToolbarExtension(app)


def preflight(app: Flask) -> list[str]:
    # SECRET_KEY is required for this extension. It is loaded and preflighted
    # by the app-general config (which runs first in the registry), so we can
    # assume it is present here.
    return []
