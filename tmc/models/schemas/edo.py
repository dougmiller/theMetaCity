from tmc.models.edo import EDO
from tmc.extensions.marshmallow import ma
from marshmallow_sqlalchemy import SQLAlchemySchema, auto_field

__all__ = ('EDOSchema')


class EDOSchema(ma.SQLAlchemyAutoSchema):
	class Meta:
		model = EDO
		load_instance = True

	id = auto_field()
	content = auto_field()
	created_at = auto_field()
	updated_at = auto_field()
