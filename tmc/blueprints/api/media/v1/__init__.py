from flask import Blueprint

api_response = {
	'result': {
		'status': None,
		'message': None
	}
}

v1 = Blueprint(
	'v1',
	__name__
)

from . import routes
