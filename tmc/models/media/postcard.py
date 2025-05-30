import os
from typing import TYPE_CHECKING

from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from tmc.models.extensions import IntegerModel

if TYPE_CHECKING:
    from tmc.models.media import MediaItem

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
        return f'''
        <picture>
            <source type="image/flif" srcset="///{kind}/postcards/{name}.flif">
            <source type="image/webp" srcset="///{kind}/postcards/{name}.webp">
            <img src="///{kind}/postcards/{self.url}" title="{self.title}" alt="{self.alt_text}">
        </picture>'''

