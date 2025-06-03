from flask import Blueprint

api_response = {
	'result': {
		'status': None,
		'message': None
	}
}

video = Blueprint(
	'video',
	__name__
)

from . import routes
