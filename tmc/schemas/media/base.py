from marshmallow_sqlalchemy import auto_field
from marshmallow_sqlalchemy.fields import Nested

from tmc.extensions.marshmallow import ma
from tmc.models.media import MediaAsset
from tmc.schemas.media.licence import LicenceSchema
from tmc.schemas.media.postcard import PostcardSchema

__all__ = "MediaAssetSchema"


class MediaAssetSchema(ma.SQLAlchemySchema):
    class Meta:
        model = MediaAsset
        load_instance = True

    id = auto_field()
    title = auto_field()
    postcard = Nested(PostcardSchema)
    licence = Nested(LicenceSchema)
