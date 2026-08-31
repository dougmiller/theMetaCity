"""Response/data caching via Flask-Caching.

Follows the extension config contract:
  * ``load_config`` — source CACHE_* from the environment (non-injected path).
  * ``preflight``   — validate only (optional keys, but valid if supplied).
  * ``init_app``    — apply defaults with ``setdefault`` and build from app.config.

All three cache settings have safe defaults, so none are required; a missing
value is filled at init, not demanded at preflight.
"""

from flask import Flask
from flask_caching import Cache

from tmc.extensions._env import raw_env

_CACHE_KEYS = ("CACHE_TYPE", "CACHE_DEFAULT_TIMEOUT", "CACHE_KEY_PREFIX")

cache: Cache = Cache()


def load_config(app: Flask) -> None:
    """Source cache config from the environment (non-injected path).

    Only keys actually present are copied, so absent env vars don't clobber the
    defaults applied in ``init_app``.
    """
    env = raw_env()
    app.config.from_mapping({key: env.get(key) for key in _CACHE_KEYS if env.get(key) is not None})


def preflight(app: Flask) -> list[str]:
    """Optional-but-must-be-valid: fail only if a supplied value is malformed."""
    timeout = app.config.get("CACHE_DEFAULT_TIMEOUT")
    if timeout is not None:
        try:
            int(timeout)
        except (TypeError, ValueError):
            return [f"CACHE_DEFAULT_TIMEOUT '{timeout}' is not an integer"]
    return []


def init_app(app: Flask) -> None:
    app.config.setdefault("CACHE_TYPE", "simple")
    app.config.setdefault("CACHE_DEFAULT_TIMEOUT", 300)
    app.config.setdefault("CACHE_KEY_PREFIX", "tmc-cache")
    # Normalise an env-sourced string ("300") to the int Flask-Caching expects.
    app.config["CACHE_DEFAULT_TIMEOUT"] = int(app.config["CACHE_DEFAULT_TIMEOUT"])

    cache.init_app(
        app,
        config={key: app.config[key] for key in _CACHE_KEYS},
    )
