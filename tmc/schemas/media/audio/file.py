from marshmallow_sqlalchemy import SQLAlchemySchema, auto_field

from tmc.models.media.audio import File

__all__ = ["FileSchema"]


class FileSchema(SQLAlchemySchema):
    class Meta:
        model = File
        load_instance = True

    id = auto_field()
    bit_rate = auto_field()
    bit_depth = auto_field()
    sample_rate = auto_field()
    vbr_encoded = auto_field()
    audio_codec = auto_field()
    mime_type = auto_field()
    extension = auto_field()
