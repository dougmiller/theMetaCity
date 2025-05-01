from flask import jsonify
from . import media


@media.route("/help")
@media.route("/")
def media_index():
	# return openAPI swagger doc (YAML)

	return jsonify(
		{
			'info': 'Media api endpoints ',
			'routes': [
				{"/v1/": "API v1"},
			]
		}
	)
