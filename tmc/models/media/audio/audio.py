from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from tmc.models.extensions.mixins import SmartQueryMixin
from tmc.models.media.asset import Asset, AssetType
from tmc.models.media.audio.file import File
from tmc.models.media.audio.track import Track


class Audio(Asset, SmartQueryMixin):
    __tablename__ = "audio"
    __table_args__ = {"schema": "media"}
    __bind_key__ = "media_selector"

    id: Mapped[int] = mapped_column(ForeignKey("media.media_item.id"), primary_key=True)
    files: Mapped[list[File]] = relationship(backref="asset")
    tracks: Mapped[list[Track]] = relationship(backref="asset")
    
    __mapper_args__ = {
        "polymorphic_identity": AssetType.audio,
    }


class AudioSelector(Audio):
    __bind_key__ = "media_selector"
    __mapper_args__ = {
        "polymorphic_abstract": True,
    }


class AudioAdmin(Audio):
    __bind_key__ = "media_admin"
    __mapper_args__ = {
        "polymorphic_abstract": True,
    }
