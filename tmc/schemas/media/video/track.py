from marshmallow_sqlalchemy import SQLAlchemySchema, auto_field

from tmc.models.media.video import Track

__all__ = ["TrackSchema"]


class TrackSchema(SQLAlchemySchema):
    class Meta:
        model = Track
        load_instance = True

    id = auto_field()
    src_lang = auto_field()
    label = auto_field()
    track_type = auto_field()
