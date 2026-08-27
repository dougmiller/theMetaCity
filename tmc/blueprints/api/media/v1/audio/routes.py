from flask.typing import ResponseReturnValue

from tmc.extensions import read_session
from tmc.queries import media as media_queries
from tmc.schemas.media.audio import AudioSchema
from tmc.utils.responses import api_response

from .bp import bp


@bp.route("/")
def all_audios() -> ResponseReturnValue:
    items = media_queries.all_audio(read_session())
    return api_response(data=AudioSchema(many=True).dump(items))


@bp.route("/<int:audio>")
def audio_details(audio: int) -> ResponseReturnValue:
    one = media_queries.audio_by_id(read_session(), audio)
    if one is None:
        return api_response(message="No matching record found", success=False, status=404)
    return api_response(data=AudioSchema().dump(one))
