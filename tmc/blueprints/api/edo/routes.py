from flask import jsonify
from flask.typing import ResponseReturnValue

from .bp import bp


@bp.route("/help")
@bp.route("/")
def edo_index() -> ResponseReturnValue:
    # return openAPI swagger doc (YAML)

    return jsonify(
        {
            "info": "Everyday Ordinary api endpoints ",
            "routes": [
                {"/v1/": "API v1"},
            ],
        }
    )
