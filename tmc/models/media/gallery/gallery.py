from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from tmc.models.extensions.mixins import SmartQueryMixin
from tmc.models.media.asset import Asset, AssetType
from tmc.models.media.gallery.image import Image


class Gallery(Asset, SmartQueryMixin):
    __tablename__ = "gallery"
    __table_args__ = {"schema": "media"}
    __bind_key__ = "media_selector"

    id: Mapped[int] = mapped_column(ForeignKey("media.media_item.id"), primary_key=True)
    images: Mapped[list[Image]] = relationship(backref="gallery")

    __mapper_args__ = {
        "polymorphic_identity": AssetType.gallery,
        "with_polymorphic": "*",
    }
