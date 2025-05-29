import os
from enum import Enum as PyEnum
from tmc.models.extensions import IntegerModel
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import String, ForeignKey, Enum as SQLEnum


class Licence(IntegerModel):
    """
    Lists all the licences that can be used by media items
    Covers all the different media types (audio/video and code etc)
    """
    __tablename__ = 'licence'
    __table_args__ = {"schema": "media"}
    __bind_key__ = "media_selector"
    
    name: Mapped[str] = mapped_column(String, unique=True)
    text: Mapped[str] = mapped_column(String, unique=True)
    url: Mapped[str] = mapped_column(String, unique=True)
    image: Mapped[str] = mapped_column(String, unique=True)
    
    media_items: Mapped[list["MediaItem"]] = relationship(back_populates="licence")
    
    def __repr__(self) -> str:
        return self.name


class Postcard(IntegerModel):  # Renamed to singular for convention
    """
    A collection of the postcards used on the front page of media.
    Broken out so that title and alt text can be used as well as
    reduced redundancy when a different project uses the same postcard
    """
    __tablename__ = 'postcard'
    __table_args__ = {"schema": "media"}
    __bind_key__ = "media_selector"
    
    url: Mapped[str] = mapped_column(String, unique=True)
    title: Mapped[str] = mapped_column(String, unique=True)
    alt_text: Mapped[str] = mapped_column(String, unique=True)
    
    media_items: Mapped[list["MediaItem"]] = relationship(back_populates="postcard", lazy="dynamic")

    def __repr__(self) -> str:
        return f"{self.url}: {self.title}"
    
    def build_picture(self, kind: str) -> str:
        name = os.path.splitext(self.url)[0]
        server = current_app.config["ASSETS_PATH"]
        return f'''
        <picture>
            <source type="image/flif" srcset="//{server}/{kind}/postcards/{name}.flif">
            <source type="image/webp" srcset="//{server}/{kind}/postcards/{name}.webp">
            <img src="//{server}/{kind}/postcards/{self.url}" title="{self.title}" alt="{self.alt_text}">
        </picture>'''


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


