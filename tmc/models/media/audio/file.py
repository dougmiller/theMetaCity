from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from enum import Enum as PyEnum
from tmc.models.extensions import IntegerModel
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import Enum as SQLEnum

__all__ = "File"

class AudioCodecType(PyEnum):
    vorbis = 'vorbis'
    mp3 = 'mp3'
    wav = 'wav'
    
    
class MimeType(PyEnum):
    webm = 'webm'
    mp3 = 'mp3'
    ogg = 'ogg'  
    mpeg = 'mpeg'
    wav = 'wav'  
    
    
class Extension(PyEnum):
    wav = 'wav'
    ogg = 'ogg'
    mp3 = 'mp3'


class File(IntegerModel):
    __tablename__ = "audio_file"
    __table_args__ = {"schema": "media"}
    __bind_key__ = "media_selector"

    parent_video: Mapped[int] = mapped_column(ForeignKey("media.media_item.id"))
    bit_rate: Mapped[int] = mapped_column()
    bit_depth: Mapped[str] = mapped_column()
    sample_rate: Mapped[str] = mapped_column()
    vbr_encoded: Mapped[bool] = mapped_column()
    audio_codec: Mapped[AudioCodecType] = mapped_column(
        SQLEnum(
            AudioCodecType,
            name="audio_audio_codec",
            schema="media",
        ) 
    )
    mime_type: Mapped[MimeType] = mapped_column(
        SQLEnum(
            MimeType,
            name="audio_mime_type",
            schema="media",
        ) 
    )
    extension: Mapped[Extension] = mapped_column(
        SQLEnum(
            Extension,
            name="audio_file_extension",
            schema="media",
        ) 
    )
