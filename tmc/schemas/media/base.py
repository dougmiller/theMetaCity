from marshmallow_sqlalchemy import auto_field
from marshmallow_sqlalchemy.fields import Nested

from tmc.extensions.marshmallow import ma
from tmc.models.media.media import MediaItem
from tmc.schemas.media.licence import LicenceSchema
from tmc.schemas.media.postcard import PostcardSchema

__all__ = "BaseSchema"


class BaseSchema(ma.SQLAlchemySchema):
    class Meta:
        model = MediaItem
        load_instance = True

    id = auto_field()
    title = auto_field()
    postcard = Nested(PostcardSchema)
    licence = Nested(LicenceSchema)
