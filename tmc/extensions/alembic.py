"""Database migrations via Flask-Alembic (no env.py; config-driven).

The ORM metadata (Base.metadata) is the single source of truth; `flask db
revision` autogenerates against it and `flask db upgrade` applies. The alembic
version table lives in its own `alembic` schema.
"""

from __future__ import annotations

import os

from flask import Flask
from flask_alembic import Alembic
from sqlalchemy.schema import SchemaItem

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


def init_app(app: Flask) -> None:
    app.config["ALEMBIC"] = {"script_location": "migrations"}
    app.config["ALEMBIC_CONTEXT"] = {
        "version_table_schema": os.environ.get("ALEMBIC_VERSION_TABLE_SCHEMA", "alembic"),
        "include_schemas": True,
        "include_object": _include_object,
    }
    alembic.init_app(app)
