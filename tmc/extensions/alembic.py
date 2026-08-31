"""Database migrations via Flask-Alembic (no env.py; config-driven).

The ORM metadata (Base.metadata) is the single source of truth; `flask db
revision` autogenerates against it and `flask db upgrade` applies. The alembic
version table lives in its own `alembic` schema.
"""

from __future__ import annotations

from flask import Flask
from flask_alembic import Alembic
from sqlalchemy.schema import SchemaItem

from tmc.extensions._env import raw_env
from tmc.extensions.sqlalchemy import Base

_TRACKED_SCHEMAS = {"com", "media", "everyday_ordinary"}


def _include_object(
    db_object: SchemaItem,
    name: str,
    type_: str,
    reflected: bool,
    compare_to: SchemaItem | None,
) -> bool:
    """Keep autogenerate focused on the app's own tables/schemas."""
    if type_ == "table":
        if name == "alembic_version":
            return False
        schema = getattr(db_object, "schema", None)
        if schema not in _TRACKED_SCHEMAS:
            return False
    return True


alembic = Alembic(metadatas=Base.metadata)

_ALEMBIC_KEYS = (
    "ALEMBIC_VERSION_TABLE_SCHEMA",
)


def load_config(app: Flask) -> None:
    """Source logging config from the environment (non-injected path)."""
    env = raw_env()
    app.config.from_mapping({key: env.get(key) for key in _ALEMBIC_KEYS if env.get(key) is not None})


def init_app(app: Flask) -> None:
    app.config.setdefault("ALEMBIC_VERSION_TABLE_SCHEMA", "alembic")


    app.config["ALEMBIC"] = {"script_location": "migrations"}
    app.config["ALEMBIC_CONTEXT"] = {
        "version_table_schema": app.config.get("ALEMBIC_VERSION_TABLE_SCHEMA"),
        "include_schemas": True,
        "include_object": _include_object,
    }
    alembic.init_app(app)
