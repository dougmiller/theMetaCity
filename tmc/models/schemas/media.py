from marshmallow_sqlalchemy import auto_field
from marshmallow_sqlalchemy.fields import Nested

from tmc.extensions.marshmallow import ma
from tmc.models.media.media import MediaItem
from tmc.models.media.postcard import Postcard
from tmc.models.media.licence import Licence

__all__ = "MediaItemSchema"


class LicenceSchema(ma.SQLAlchemySchema):
    class Meta:
        model = Licence
        load_instance = True

    id = auto_field()
    name = auto_field()
    text = auto_field()
    url = auto_field()
    image = auto_field()


class PostcardSchema(ma.SQLAlchemySchema):
    class Meta:
        model = Postcard
        load_instance = True

    id = auto_field()
    title = auto_field()
    url = auto_field()


class MediaItemSchema(ma.SQLAlchemySchema):
    class Meta:
        model = MediaItem
        load_instance = True

    id = auto_field()
    title = auto_field()
    postcard = Nested(PostcardSchema)
    licence = Nested(LicenceSchema)
