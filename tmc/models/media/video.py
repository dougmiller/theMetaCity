from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from tmc.models.media import MediaItem, MediaType


class Video(MediaItem):
	__tablename__ = "video"
	__table_args__ = {"schema": "media"}
	__bind_key__ = "media_selector"
	__mapper_args__ = {
		'polymorphic_identity': MediaType.video
	}
	
	id: Mapped[int] = mapped_column(ForeignKey("media.media_item.id"), primary_key=True)
