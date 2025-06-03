from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from tmc.models.extensions.mixins.query import BoundQueryMixin, QueryMixin
from tmc.models.media.media import MediaItem, MediaType


class Video(MediaItem):
	__tablename__ = "video"
	__table_args__ = {"schema": "media"}
	__bind_key__ = "media_selector"
	
	id: Mapped[int] = mapped_column(ForeignKey("media.media_item.id"), primary_key=True)

	__mapper_args__ = {
		'polymorphic_identity': MediaType.video
	}


class VideoSelector(Video, BoundQueryMixin, QueryMixin):
    __bind_key__ = "media_selector"
    __mapper_args__ = {
        "polymorphic_abstract": True,
    }


class VideoAdmin(Video, BoundQueryMixin, QueryMixin):
    __bind_key__ = "media_admin"
    __mapper_args__ = {
        "polymorphic_abstract": True,
    }
