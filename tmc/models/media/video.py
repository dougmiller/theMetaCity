from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from tmc.models.extensions.mixins import SmartQueryMixin
from tmc.models.media import AssetType, MediaAsset


class Video(MediaAsset):
    __tablename__ = "video"
    __table_args__ = {"schema": "media"}
    __bind_key__ = "media_selector"

    id: Mapped[int] = mapped_column(ForeignKey("media.media_item.id"), primary_key=True)

    __mapper_args__ = {
        "polymorphic_identity": AssetType.video,
    }


class VideoSelector(Video, SmartQueryMixin):
    __bind_key__ = "media_selector"
    __mapper_args__ = {
        "polymorphic_abstract": True,
    }


class VideoAdmin(Video, SmartQueryMixin):
    __bind_key__ = "media_admin"
    __mapper_args__ = {
        "polymorphic_abstract": True,
    }
