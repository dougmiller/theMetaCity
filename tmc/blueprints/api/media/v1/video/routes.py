from flask.typing import ResponseReturnValue

from tmc.extensions import read_session
from tmc.queries import media as media_queries
from tmc.schemas.media.video import VideoSchema
from tmc.utils.responses import api_response

from .bp import bp as video


@video.route("/")
def all_videos() -> ResponseReturnValue:
    items = media_queries.all_video(read_session())
    return api_response(data=VideoSchema(many=True).dump(items))


@video.route("/<int:video>")
def video_details(video: int) -> ResponseReturnValue:
    one = media_queries.video_by_id(read_session(), video)
    if one is None:
        return api_response(message="No matching record found", success=False, status=404)
    return api_response(data=VideoSchema().dump(one))


@video.route("/follow_on/<int:video>/")
@video.route("/follow_on/")
def video_follow_on(video=None) -> ResponseReturnValue:
    items = media_queries.random_videos(read_session(), exclude_id=video, limit=2)
    return api_response(data=VideoSchema(many=True).dump(items))
