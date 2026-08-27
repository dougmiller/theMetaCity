from marshmallow_sqlalchemy import SQLAlchemySchema, auto_field

from tmc.models.media.video import File

__all__ = ["FileSchema"]


class FileSchema(SQLAlchemySchema):
    class Meta:
        model = File
        load_instance = True

    id = auto_field()
    video_codec = auto_field()
    audio_codec = auto_field()
    extension = auto_field()
    resolution = auto_field()
    mime_type = auto_field()
    file_size = auto_field()
    is_fullscreen = auto_field()
