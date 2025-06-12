from marshmallow_sqlalchemy import auto_field

from tmc.extensions.marshmallow import ma
from tmc.models.media.video import Track

__all__ = "TrackSchema"


class TrackSchema(ma.SQLAlchemySchema):
    class Meta:
        model = Track
        load_instance = True

    id = auto_field()
    src_lang = auto_field()
    label = auto_field()
    track_type = auto_field()
