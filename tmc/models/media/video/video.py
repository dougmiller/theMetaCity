from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from tmc.models.extensions.mixins import SmartQueryMixin
from tmc.models.media.asset import Asset, AssetType
from tmc.models.media.video.file import File
from tmc.models.media.video.track import Track


class Video(Asset, SmartQueryMixin):
    __tablename__ = "video"
    __table_args__ = {"schema": "media"}
    __bind_key__ = "media_selector"

    id: Mapped[int] = mapped_column(ForeignKey("media.media_item.id"), primary_key=True)
    files: Mapped[list[File]] = relationship(backref="asset")
    tracks: Mapped[list[Track]] = relationship(backref="asset")
    
    __mapper_args__ = {
        "polymorphic_identity": AssetType.video,
    }


class VideoSelector(Video):
    __bind_key__ = "media_selector"
    __mapper_args__ = {
        "polymorphic_abstract": True,
    }


class VideoAdmin(Video):
    __bind_key__ = "media_admin"
    __mapper_args__ = {
        "polymorphic_abstract": True,
    }
