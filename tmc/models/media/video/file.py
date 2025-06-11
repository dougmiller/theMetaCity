from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from enum import Enum as PyEnum
from tmc.models.extensions import IntegerModel
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import Enum as SQLEnum

class VideoCodecType(PyEnum):
    vp8 = 'vp8'
    h264 = 'h264'
    theora = 'theora'


class AudioCodecType(PyEnum):
    nill = 'nill'
    vorbis = 'vorbis'
    mp3 = 'mp3'
    wav = 'wav'
    
    
class MimeType(PyEnum):
    webm = 'webm'
    mp4 = 'mp4'
    ogg = 'ogg'  
    
    
class Extension(PyEnum):
    webm = 'webm'
    ogv = 'ogv'
    mp4 = 'mp4'


class File(IntegerModel):
    __tablename__ = "video_file"
    __table_args__ = {"schema": "media"}
    __bind_key__ = "media_selector"

    parent_video: Mapped[int] = mapped_column(ForeignKey("media.media_item.id"))
    file_size: Mapped[int] = mapped_column()
    resolution: Mapped[str] = mapped_column()
    is_fullscreen: Mapped[bool] = mapped_column()
    video_codec: Mapped[VideoCodecType] = mapped_column(
        SQLEnum(
            VideoCodecType,
            name="video_video_codec",
            schema="media",
        ), 
        nullable=False, 
    )
    audio_codec: Mapped[AudioCodecType] = mapped_column(
        SQLEnum(
            AudioCodecType,
            name="video_audio_codec",
            schema="media",
        ) 
    )
    mime_type: Mapped[MimeType] = mapped_column(
        SQLEnum(
            MimeType,
            name="video_mime_type",
            schema="media",
        ) 
    )
    extension: Mapped[Extension] = mapped_column(
        SQLEnum(
            Extension,
            name="video_file_extension",
            schema="media",
        ) 
    )
