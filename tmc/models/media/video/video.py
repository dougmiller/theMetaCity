from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from tmc.models.extensions.mixins import SmartQueryMixin
from tmc.models.media.asset import Asset, AssetType
from tmc.models.media.video.file import File
from tmc.models.media.video.track import Track

__all__ = ("Video", "VideoAdmin")


class Video(Asset, SmartQueryMixin):
    __tablename__ = "video"
    __table_args__ = {"schema": "media"}
    __bind_key__ = "media_selector"

    id: Mapped[int] = mapped_column(ForeignKey("media.media_item.id"), primary_key=True)
    files: Mapped[list[File]] = relationship(backref="asset")
    tracks: Mapped[list[Track]] = relationship(backref="asset")

    __mapper_args__ = {
        "polymorphic_identity": AssetType.video,
        "with_polymorphic": "*",
    }



def bind_specific_video_class(bind_key: str):
    class BoundVideo(Video):
        __abstract__ = True
        __bind_key__ = bind_key
        __mapper_args__ = {
            "with_polymorphic": "*",
        }
    BoundVideo.__name__ = f"Video_{bind_key.capitalize()}"
    return BoundVideo


VideoAdmin = bind_specific_video_class("media_admin")
    