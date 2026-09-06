from __future__ import annotations

import uuid

import arrow
from sqlalchemy import ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from tmc.models.extensions import UUIDModel
from tmc.models.extensions.mixins import TimestampsMixin

__all__ = ("EDO", "EdoMedia")


class EDO(UUIDModel, TimestampsMixin):
    __tablename__ = "everyday_ordinary"
    __table_args__ = {"schema": "everyday_ordinary"}

    content: Mapped[str]

    # Media attached to this post. Ordered by the client-supplied position and
    # removed with the post (delete-orphan; the DB FK also cascades).
    media: Mapped[list[EdoMedia]] = relationship(
        back_populates="edo",
        order_by="EdoMedia.position",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

    def command_line_str(self) -> str:
        cd = arrow.get(self.created_at)
        return f"{cd.humanize()} - {self.content}"

    def command_line_listing_str(self) -> str:
        cd = arrow.get(self.created_at)
        return f"{self.id} - {cd.humanize()} - {self.content}"

    def __str__(self) -> str:
        return f"{self.id} – {self.created_at} - {self.content}"  # noqa: RUF001

    def __repr__(self) -> str:
        return f"{self.id} – {self.content}"  # noqa: RUF001


class EdoMedia(UUIDModel):
    """A single media object attached to an :class:`EDO` post.

    The bytes live in S3 (object storage); this row only records the object
    ``s3_key`` the client uploaded to via the presign pathway, plus its
    declared ``content_type``, a coarse ``kind`` (image/video/audio/file) for
    rendering and filtering, and its ``position`` within the post.
    """

    __tablename__ = "edo_media"
    __table_args__ = {"schema": "everyday_ordinary"}

    edo_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey(
            "everyday_ordinary.everyday_ordinary.id",
            ondelete="CASCADE",
            onupdate="CASCADE",
        ),
        nullable=False,
        index=True,
    )
    s3_key: Mapped[str] = mapped_column(String, nullable=False)
    content_type: Mapped[str | None] = mapped_column(String, nullable=True)
    kind: Mapped[str] = mapped_column(String, nullable=False, default="file", server_default="file")
    position: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")

    edo: Mapped[EDO] = relationship(back_populates="media")

    def __repr__(self) -> str:
        return f"<EdoMedia {self.id} {self.kind} {self.s3_key}>"
