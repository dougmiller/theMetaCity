"""Data-access layer — session-first query functions.

Every function takes a ``session`` as its first argument (the caller decides
read vs write by passing ``read_session()`` or ``db.session``). Read functions
never commit; writes commit explicitly via :func:`save` / :func:`delete`.
"""

from __future__ import annotations

import uuid
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import DeclarativeBase, Session


def save[M](session: Session, obj: M) -> M:
    """Add ``obj`` and commit."""
    session.add(obj)
    session.commit()
    return obj


def delete(session: Session, obj: object) -> None:
    """Delete ``obj`` and commit."""
    session.delete(obj)
    session.commit()


def get_by_pk[M: DeclarativeBase](session: Session, model: type[M], pk: Any) -> M | None:
    """Fetch one row by primary key.

    Coerces ``str`` to ``uuid.UUID`` / ``int`` as appropriate and guards the
    PostgreSQL INTEGER range (out-of-range ints and non-coercible values return
    ``None`` rather than raising), matching the old mixin behaviour the API 404s
    rely on.
    """
    pk_col = model.__mapper__.primary_key[0]
    pk_type = getattr(pk_col.type, "python_type", None)
    is_uuid = isinstance(pk_type, type) and issubclass(pk_type, uuid.UUID)

    try:
        if isinstance(pk, str):
            if is_uuid:
                pk = uuid.UUID(pk)
            elif pk.isdigit():
                pk = int(pk)
        elif isinstance(pk, float):
            return None
        if isinstance(pk, int) and isinstance(pk_type, type) and issubclass(pk_type, int) and not -(2**31) <= pk <= 2**31 - 1:
            return None
    except ValueError, TypeError, OverflowError:
        return None

    return session.scalars(select(model).where(pk_col == pk).limit(1)).first()
