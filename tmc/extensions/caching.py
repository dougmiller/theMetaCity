from flask import Flask
from flask_caching import Cache

cache: Cache = Cache()


def init_app(app: Flask) -> None:
    cache.init_app(
        app,
        config={
            "CACHE_TYPE": app.config.get("CACHE_TYPE", "simple"),
            "CACHE_DEFAULT_TIMEOUT": app.config.get("CACHE_DEFAULT_TIMEOUT", 300),
            "CACHE_KEY_PREFIX": app.config.get("CACHE_KEY_PREFIX", "tmc-cache"),
        },
    )


def preflight(app: Flask) -> list[str]:
    # All cache settings have safe defaults, so none are strictly required.
    return []
