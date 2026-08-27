from typing import Any

from flask import abort
from sqlalchemy.orm import Session
from sqlalchemy.sql import Select


def one_or_404(session: Session, stmt: Select) -> Any:
    """Return the first scalar result or abort(404)."""
    obj = session.scalars(stmt).first()
    if obj is None:
        abort(404)
    return obj
