from marshmallow_sqlalchemy.fields import Nested

from tmc.models.media.audio import Audio
from tmc.schemas.media.audio.file import FileSchema
from tmc.schemas.media.audio.track import TrackSchema
from tmc.schemas.media.base import AssetSchema

__all__ = ["AudioSchema"]


class AudioSchema(AssetSchema):
    class Meta:
        model = Audio
        load_instance = True

    files = Nested(FileSchema, many=True)
    tracks = Nested(TrackSchema, many=True)
