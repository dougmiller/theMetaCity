from marshmallow_sqlalchemy import auto_field
from marshmallow_sqlalchemy.fields import Nested

from tmc.extensions.marshmallow import ma
from tmc.models.media.gallery import Gallery
from tmc.schemas.media.base import AssetSchema
from tmc.schemas.media.image import ImageSchema

__all__ = "GallerySchema"


class GallerySchema(AssetSchema):
    class Meta:
        model = Gallery
        load_instance = True

    images = Nested(ImageSchema, many=True)
