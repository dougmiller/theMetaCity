from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from tmc.models.extensions import UUIDModel
from tmc.models.extensions.mixins import SmartQueryMixin


class Image(UUIDModel, SmartQueryMixin):
    """
    Represents an image that can be added to a Gallery.

    NB: They do not have to be, but the design of the site assumes it otherwise.
    """

    __tablename__ = "image"
    __table_args__ = {"schema": "media"}
    __bind_key__ = "media_selector"

    path: Mapped[str] = mapped_column()

    gallery_id: Mapped[int | None] = mapped_column(
        ForeignKey(
            "media.gallery.id",
            ondelete="SET NULL",
            onupdate="CASCADE",
        ),
        nullable=True,
    )
