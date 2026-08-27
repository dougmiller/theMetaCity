from flask import jsonify
from flask.typing import ResponseReturnValue

from .bp import bp as media


@media.route("/help")
@media.route("/")
def media_index() -> ResponseReturnValue:
    # return openAPI swagger doc (YAML)

    return jsonify(
        {
            "info": "Media api endpoints ",
            "routes": [
                {"/v1/": "API v1"},
            ],
        }
    )
