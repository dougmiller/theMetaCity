from flask import abort, render_template
from flask.typing import ResponseReturnValue

from tmc.extensions import read_session
from tmc.queries import media as media_queries

from .bp import bp as video


@video.route("/")
def all() -> ResponseReturnValue:
    videos = media_queries.all_video(read_session())
    return render_template("index.jinja2", videos=videos)


@video.route("/<int:id>/")
def single(id) -> ResponseReturnValue:
    item = media_queries.video_by_id(read_session(), id)
    if item is None:
        abort(404)
    return render_template("media/video/single.jinja2", video=item)
