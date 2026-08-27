from marshmallow_sqlalchemy import SQLAlchemySchema, auto_field
from marshmallow_sqlalchemy.fields import Nested

from tmc.models.media import Asset
from tmc.schemas.media.licence import LicenceSchema
from tmc.schemas.media.postcard import PostcardSchema

__all__ = ["AssetSchema"]


class AssetSchema(SQLAlchemySchema):
    class Meta:
        model = Asset
        load_instance = True

    id = auto_field()
    title = auto_field()
    postcard = Nested(PostcardSchema)
    licence = Nested(LicenceSchema)
