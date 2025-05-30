from enum import Enum as PyEnum

from sqlalchemy import Enum as SQLEnum
from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from tmc.models.media.licence import Licence
from tmc.models.media.postcard import Postcard
from tmc.models.extensions import IntegerModel


class MediaType(PyEnum):
    video = 'video'
    audio = 'audio'
    gallery = 'gallery'


class MediaItem(IntegerModel):
    __tablename__ = "media_item"
    __table_args__ = {"schema": "media"}
    __bind_key__ = "media_selector"

    title: Mapped[str] = mapped_column(String)
    media_type: Mapped[MediaType] = mapped_column(
        SQLEnum(
            MediaType,
            name="media_type_enum",
            schema="media"
        ), 
        nullable=False, 
    )
    licence_id: Mapped[int] = mapped_column(ForeignKey("media.licence.id"))
    licence: Mapped["Licence"] = relationship(back_populates="media_items")
    
    postcard_id: Mapped[int] = mapped_column(ForeignKey("media.postcard.id"))
    postcard: Mapped["Postcard"] = relationship(back_populates="media_items")

    __mapper_args__ = {
        "polymorphic_on": media_type,
    }
    
    def __repr__(self):
        return f"<MediaItem {self.id} - {self.media_type}>"


