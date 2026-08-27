from marshmallow_sqlalchemy import SQLAlchemySchema, auto_field

from tmc.models.media import Postcard


class PostcardSchema(SQLAlchemySchema):
    class Meta:
        model = Postcard
        load_instance = True

    id = auto_field()
    title = auto_field()
    url = auto_field()
