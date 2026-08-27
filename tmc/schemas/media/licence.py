from marshmallow_sqlalchemy import SQLAlchemySchema, auto_field

from tmc.models.media import Licence


class LicenceSchema(SQLAlchemySchema):
    class Meta:
        model = Licence
        load_instance = True

    id = auto_field()
    name = auto_field()
    text = auto_field()
    url = auto_field()
    image = auto_field()
