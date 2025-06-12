from marshmallow_sqlalchemy.fields import Nested

from tmc.models.media.video import Video
from tmc.schemas.media.base import AssetSchema
from tmc.schemas.media.video import FileSchema, TrackSchema

__all__ = "VideoSchema"


class VideoSchema(AssetSchema):
    class Meta:
        model = Video
        load_instance = True

    files = Nested(FileSchema, many=True)
    tracks = Nested(TrackSchema, many=True)
