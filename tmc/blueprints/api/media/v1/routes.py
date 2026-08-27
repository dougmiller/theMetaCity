from flask import jsonify
from flask.typing import ResponseReturnValue

from tmc.extensions import read_session
from tmc.queries import media as media_queries
from tmc.schemas.media import AssetSchema
from tmc.utils.responses import api_response

from .bp import bp


@bp.route("/help/")
@bp.route("/")
def media_v1_index() -> ResponseReturnValue:
    return jsonify(
        {
            "info": "Media api endpoints ",
            "routes": [
                {"endoint": "/help", "description": "This information"},
                {"endoint": "/video", "description": "Returns a video's details"},
            ],
        }
    )


@bp.route("/all")
def all() -> ResponseReturnValue:
    assets = media_queries.all_assets(read_session())
    return api_response(data=AssetSchema(many=True).dump(assets))
