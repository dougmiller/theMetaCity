"""Audio media item in the polymorphic Asset hierarchy."""

from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from tmc.models.media.asset import Asset, AssetType
from tmc.models.media.audio.file import File
from tmc.models.media.audio.track import Track

__all__ = ("Audio",)


class Audio(Asset):
    __tablename__ = "audio"
    __table_args__ = {"schema": "media"}

    id: Mapped[int] = mapped_column(ForeignKey("media.media_item.id"), primary_key=True)
    files: Mapped[list[File]] = relationship(backref="asset")
    tracks: Mapped[list[Track]] = relationship(backref="asset")

    __mapper_args__ = {
        "polymorphic_identity": AssetType.audio,
        "with_polymorphic": "*",
    }

    def format_running_time_to_human_readable(self) -> str:
        return "123"

