from flask import Blueprint

audio = Blueprint(
	'audio',
	__name__
)

from . import routes
