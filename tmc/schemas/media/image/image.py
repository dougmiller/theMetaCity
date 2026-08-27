from marshmallow import fields
from marshmallow_sqlalchemy import SQLAlchemySchema, auto_field

from tmc.models.media.gallery import Image

__all__ = ["ImageSchema"]


class ImageSchema(SQLAlchemySchema):
    class Meta:
        model = Image
        load_instance = True

    id = fields.UUID()
    path = auto_field()
