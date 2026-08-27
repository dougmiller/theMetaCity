from flask import Flask


def init_app(app: Flask) -> None:
    # SECRET_KEY / SERVER_NAME / paths are populated by the config loader (the
    # configs package on the .env path, or the injected mapping in tests).
    # Ensure FLASK_DEBUG always has a value for downstream consumers.
    app.config.setdefault("FLASK_DEBUG", False)


def preflight(app: Flask) -> list[str]:
    errors: list[str] = []
    if not app.config.get("SECRET_KEY"):
        errors.append("SECRET_KEY not set")
    return errors
