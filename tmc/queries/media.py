"""Media (asset / audio / video / gallery / image) queries."""

from __future__ import annotations

import uuid
from collections.abc import Sequence

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from tmc.models.media import Asset, Audio, Gallery, Image, Video
from tmc.queries import get_by_pk


def all_assets(session: Session) -> Sequence[Asset]:
    return session.scalars(select(Asset).order_by(Asset.date_published.desc())).all()


def all_audio(session: Session) -> Sequence[Audio]:
    return session.scalars(select(Audio).order_by(Audio.date_published.desc())).all()


def audio_by_id(session: Session, pk: int) -> Audio | None:
    return get_by_pk(session, Audio, pk)


def all_video(session: Session) -> Sequence[Video]:
    return session.scalars(select(Video).order_by(Video.date_published.desc())).all()


def video_by_id(session: Session, pk: int) -> Video | None:
    return get_by_pk(session, Video, pk)


def random_videos(session: Session, exclude_id: int | None = None, limit: int = 2) -> Sequence[Video]:
    stmt = select(Video).order_by(func.random()).limit(limit)
    if exclude_id is not None:
        stmt = stmt.where(Video.id != exclude_id)
    return session.scalars(stmt).all()


def all_gallery(session: Session) -> Sequence[Gallery]:
    return session.scalars(select(Gallery).order_by(Gallery.date_published.desc())).all()


def gallery_by_id(session: Session, pk: int) -> Gallery | None:
    return get_by_pk(session, Gallery, pk)


def all_image(session: Session) -> Sequence[Image]:
    return session.scalars(select(Image)).all()


def image_by_id(session: Session, pk: uuid.UUID) -> Image | None:
    return get_by_pk(session, Image, pk)
