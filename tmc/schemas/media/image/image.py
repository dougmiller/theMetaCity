from marshmallow_sqlalchemy import auto_field

from tmc.extensions.marshmallow import ma
from tmc.models.media.gallery import Image
from tmc.schemas.media.base import AssetSchema

__all__ = "ImageSchema"


class ImageSchema(AssetSchema):
    class Meta:
        model = Image
        load_instance = True

    id = ma.UUID()
    path = auto_field()
