from flask import Blueprint
from .v1 import v1

media = Blueprint(
	'media',
	__name__
)

media.register_blueprint(v1, url_prefix="/v1")

from . import routes
