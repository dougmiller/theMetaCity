from enum import StrEnum

from sqlalchemy import Enum as SQLEnum
from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy_utils import ArrowType

from tmc.models.extensions import IntegerModel
from tmc.models.media.licence import Licence
from tmc.models.media.postcard import Postcard


class AssetType(StrEnum):
    video = "video"
    audio = "audio"
    gallery = "gallery"


class Asset(IntegerModel):
    __tablename__ = "media_item"
    __table_args__ = {"schema": "media"}

    title: Mapped[str] = mapped_column(String)
    about: Mapped[str] = mapped_column(String)

    date_published: Mapped[ArrowType] = mapped_column(ArrowType)

    licence_id: Mapped[int] = mapped_column(ForeignKey("media.licence.id"))
    licence: Mapped[Licence] = relationship(backref="media_items")

    postcard_id: Mapped[int] = mapped_column(ForeignKey("media.postcard.id"))
    postcard: Mapped[Postcard] = relationship(backref="media_items")

    media_type: Mapped[AssetType] = mapped_column(
        SQLEnum(
            AssetType,
            name="media_type_enum",
            schema="media",
        ),
        nullable=False,
    )

    __default_order_by__ = date_published.desc()

    __mapper_args__ = {
        "polymorphic_on": media_type,
    }

    def __repr__(self) -> str:
        return f"<MediaAsset {self.id} - {self.media_type}>"
