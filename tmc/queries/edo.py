"""EDO (everyday_ordinary) queries."""

from __future__ import annotations

import uuid
from collections.abc import Sequence

from sqlalchemy import select
from sqlalchemy.orm import Session

from tmc.models.edo import EDO
from tmc.queries import get_by_pk


def all_edo(session: Session) -> Sequence[EDO]:
    return session.scalars(select(EDO).order_by(EDO.created_at.desc())).all()


def latest(session: Session, limit: int = 10) -> Sequence[EDO]:
    return session.scalars(select(EDO).order_by(EDO.created_at.desc()).limit(limit)).all()


def by_id(session: Session, record: uuid.UUID) -> EDO | None:
    return get_by_pk(session, EDO, record)


def search_content(session: Session, term: str) -> Sequence[EDO]:
    return session.scalars(select(EDO).where(EDO.content.ilike(f"%{term}%")).order_by(EDO.created_at.desc())).all()
