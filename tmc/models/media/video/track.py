from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from enum import Enum as PyEnum
from tmc.models.extensions import IntegerModel
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import Enum as SQLEnum


class VideoTrackType(PyEnum):
    subtitles = 'subtitles'
    captions = 'captions'
    descriptions = 'descriptions'
    chapters = 'chapters'
    metadata = 'metadata'


class Track(IntegerModel):
    __tablename__ = "video_track"
    __table_args__ = {"schema": "media"}
    __bind_key__ = "media_selector"

    parent_video: Mapped[int] = mapped_column(ForeignKey("media.media_item.id"))
    src_lang: Mapped[str] = mapped_column()
    label: Mapped[str] = mapped_column()
    track_type: Mapped[VideoTrackType] = mapped_column(
        SQLEnum(
            VideoTrackType,
            name="video_track_type",
            schema="media",
        ), 
        nullable=False, 
    )
