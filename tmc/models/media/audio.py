from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from tmc.models.media import MediaItem, MediaType


class Audio(MediaItem):
    #__abstract__ = True
    __tablename__ = "audio"
    __table_args__ = {"schema": "media"}
    
    id: Mapped[int] = mapped_column(
        ForeignKey("media.media_item.id"),
        primary_key=True
    )
    
    __mapper_args__ = {
        "polymorphic_identity": MediaType.audio,
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
