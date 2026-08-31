"""Application logging (dictConfig-based, deterministic and idempotent).

Follows the extension config contract:
  * ``load_config`` — source LOG_* from the environment (non-injected path).
  * ``preflight``   — validate only (optional, but valid if supplied).
  * ``init_app``    — apply defaults with ``setdefault`` and configure logging.

Registered first so later extensions' boot logs are already formatted. Logs to
stdout by default (12-factor: let the platform route); a file sink is opt-in
via LOG_FILE and rotates, so it never grows unbounded or crashes boot on a
read-only filesystem.
"""

import logging.config
import sys

from flask import Flask

from tmc.extensions._env import raw_env

_LOG_KEYS = ("LOG_LEVEL", "LOG_FILE")


def load_config(app: Flask) -> None:
    """Source logging config from the environment (non-injected path)."""
    env = raw_env()
    app.config.from_mapping({key: env.get(key) for key in _LOG_KEYS if env.get(key) is not None})


def preflight(app: Flask) -> list[str]:
    """Optional-but-must-be-valid: fail only if LOG_LEVEL is set and unknown."""
    level = app.config.get("LOG_LEVEL")
    if level is not None and str(level).upper() not in logging.getLevelNamesMapping():
        return [f"LOG_LEVEL '{level}' is not a valid logging level"]
    return []


def init_app(app: Flask) -> None:
    level = str(app.config.setdefault("LOG_LEVEL", "INFO")).upper()
    log_file = app.config.setdefault("LOG_FILE", None)

    handlers: dict[str, dict] = {
        "console": {"class": "logging.StreamHandler", "stream": sys.stdout, "formatter": "default"},
    }
    if log_file:  # opt-in; rotating so it never grows unbounded
        handlers["file"] = {
            "class": "logging.handlers.RotatingFileHandler",
            "filename": log_file,
            "maxBytes": 10_485_760,
            "backupCount": 3,
            "encoding": "utf-8",
            "formatter": "default",
        }

    logging.config.dictConfig({
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {"default": {"style": "{", "format": "{asctime} {levelname} {name} {message}"}},
        "handlers": handlers,
        "root": {"level": level, "handlers": list(handlers)},
    })
