"""Application-general configuration.

These settings belong to the app itself rather than to any single extension.
On the normal boot path ``load_config`` populates them from the environment;
on the injected path (tests) they arrive via ``create_app(config=...)`` and
this module only fills defaults and validates.
"""

from flask import Flask

from tmc.extensions._env import raw_env

# App-general keys — owned by the app, not by any one extension.
_APP_KEYS = (
    "SERVER_NAME",
    "DEBUG",
    "SECRET_KEY",
    "CSRF_ENABLED",
    "EDO_UPLOAD_PATH",
    "ASSETS_PATH",
    "DOCUMENTS_FOLDER_PATH",
)


def load_config(app: Flask) -> None:
    """Populate app-general config from the environment (non-injected path)."""
    env = raw_env()
    app.config.from_mapping({key: env.get(key) for key in _APP_KEYS})


def init_app(app: Flask) -> None:
    # Ensure FLASK_DEBUG always has a value for downstream consumers
    # (e.g. the debug toolbar), regardless of how config was sourced.
    app.config.setdefault("FLASK_DEBUG", False)


def preflight(app: Flask) -> list[str]:
    errors: list[str] = []
    if not app.config.get("SECRET_KEY"):
        errors.append("SECRET_KEY not set")
    return errors
