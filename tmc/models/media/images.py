from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from tmc.models.media import MediaItem, MediaType
from tmc.models.extensions import UUIDModel


class Gallery(MediaItem):
	__tablename__ = "gallery"
	__table_args__ = {"schema": "media"}
	__bind_key__ = "media"
	__mapper_args__ = {
		"polymorphic_identity": MediaType.gallery
	}

	id: Mapped[int] = mapped_column(
		ForeignKey("media.media_item.id"),
		primary_key=True
	)

	items: Mapped[list["Image"]] = relationship(
		back_populates="gallery",
		passive_deletes=True,
		cascade="save-update, merge",
		lazy="select"
	)


class Image(UUIDModel):
	"""
	Represents an image that can be added to a Gallery.

	NB: They do not have to be, but the design of the site assumes it otherwise.
	"""
	__tablename__ = "image"
	__table_args__ = {"schema": "media"}
	__bind_key__ = "media"

	gallery_id: Mapped[int | None] = mapped_column(
		ForeignKey(
			"media.gallery.id",
			ondelete="SET NULL",
			onupdate="CASCADE"
		),
		nullable=True
	)
	gallery: Mapped[Gallery | None] = relationship(
		back_populates="items"
	)