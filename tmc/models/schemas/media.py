from tmc.models.media import MediaItem, Licence, Postcard
from tmc.extensions.marshmallow import ma
from marshmallow_sqlalchemy import SQLAlchemySchema, auto_field
from marshmallow_sqlalchemy.fields import Nested

__all__ = ('MediaItemSchema')


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


