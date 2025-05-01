from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from tmc.models.media import MediaItem, MediaType
from tmc.models.extensions import UUIDModel

class Gallery(MediaItem):
	__tablename__ = "gallery"
	__table_args__ = {"schema": "media"}
	__bind_key__ = "media"
	__mapper_args__ = {
		'polymorphic_identity': MediaType.gallery
	}
	
	id: Mapped[int] = mapped_column(ForeignKey("media.media_item.id"), primary_key=True)

	items: Mapped[list["Image"]] = relationship(
		back_populates="gallery",
		cascade="all, delete-orphan",
		lazy="select"
	)


class Image(UUIDModel):
	'''   
	This design supports the concept of orphaned entries by allowing `gallery_id` to remain nullable or unset, 
	depending on the broader schema and application logic. An image can exist independently of a gallery if needed, 
	while still enabling tallying via `gallery_id` when present. This makes it possible to treat a lone image as a 
	gallery of one, ensuring flexibility in the way media items are organized and displayed.
	'''
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
	gallery: Mapped[Gallery | None] = relationship(back_populates="items")
