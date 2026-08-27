from flask import jsonify
from flask.typing import ResponseReturnValue

from .bp import bp


@bp.route("/help/")
@bp.route("/")
def api_index() -> ResponseReturnValue:
    # Todo: Turn into Open API spec
    return jsonify(
        {
            "info": "Basic info on tmc api ",
            "routes": [
                {"/help/": "This information"},
                {"/edo/": "Everyday Ordinary uploader"},
            ],
        }
    )
