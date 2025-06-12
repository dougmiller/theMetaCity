from enum import Enum as PyEnum

from sqlalchemy import Enum as SQLEnum
from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from tmc.models.extensions import IntegerModel


class AudioTrackType(PyEnum):
    subtitles = "subtitles"
    captions = "captions"
    descriptions = "descriptions"
    chapters = "chapters"
    metadata = "metadata"


class Track(IntegerModel):
    __tablename__ = "audio_track"
    __table_args__ = {"schema": "media"}
    __bind_key__ = "media_selector"

    parent_audio: Mapped[int] = mapped_column(ForeignKey("media.media_item.id"))
    src_lang: Mapped[str] = mapped_column()
    label: Mapped[str] = mapped_column()
    track_type: Mapped[AudioTrackType] = mapped_column(
        SQLEnum(
            AudioTrackType,
            name="audio_track_type",
            schema="media",
        ),
        nullable=False,
    )
