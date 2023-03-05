from flask import jsonify
from . import edo


@edo.route("/help")
@edo.route("/")
def edo_index():
    # return openAPI swagger doc (YAML)

    return jsonify(
        {
            'info': 'Everyday Ordinary api endpoints ',
            'routes': [
                {"/v1": "API v1"},
            ]
        }
    )
