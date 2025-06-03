from marshmallow_sqlalchemy import auto_field

from tmc.extensions.marshmallow import ma
from tmc.models.media.licence import Licence


class LicenceSchema(ma.SQLAlchemySchema):
    class Meta:
        model = Licence
        load_instance = True

    id = auto_field()
    name = auto_field()
    text = auto_field()
    url = auto_field()
    image = auto_field()
