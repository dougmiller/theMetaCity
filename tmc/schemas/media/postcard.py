from marshmallow_sqlalchemy import auto_field

from tmc.extensions.marshmallow import ma
from tmc.models.media import Postcard


class PostcardSchema(ma.SQLAlchemySchema):
    class Meta:
        model = Postcard
        load_instance = True

    id = auto_field()
    title = auto_field()
    url = auto_field()
