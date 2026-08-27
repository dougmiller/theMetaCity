from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from tmc.models.media.asset import Asset, AssetType
from tmc.models.media.video.file import File
from tmc.models.media.video.track import Track

__all__ = ("Video", "VideoAdmin")


class Video(Asset):
    __tablename__ = "video"
    __table_args__ = {"schema": "media"}

    id: Mapped[int] = mapped_column(ForeignKey("media.media_item.id"), primary_key=True)
    files: Mapped[list[File]] = relationship(backref="asset")
    tracks: Mapped[list[Track]] = relationship(backref="asset")

    __mapper_args__ = {
        "polymorphic_identity": AssetType.video,
        "with_polymorphic": "*",
    }


VideoAdmin = Video
