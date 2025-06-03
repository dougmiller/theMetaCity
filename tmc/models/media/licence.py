from marshmallow_sqlalchemy import auto_field
from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from tmc.extensions.marshmallow import ma
from tmc.models.extensions import IntegerModel


class Licence(IntegerModel):
    """
    Lists all the licences that can be used by media items
    Covers all the different media types (audio/video and code etc)
    """

    __tablename__ = "licence"
    __table_args__ = {"schema": "media"}
    __bind_key__ = "media_selector"

    name: Mapped[str] = mapped_column(String, unique=True)
    text: Mapped[str] = mapped_column(String, unique=True)
    url: Mapped[str] = mapped_column(String, unique=True)
    image: Mapped[str] = mapped_column(String, unique=True)

    # Back ref on MediaItem sorts this out
    # media_items: Mapped[list["MediaItem"]] = relationship(back_populates="licence")

    def __repr__(self) -> str:
        return self.name
