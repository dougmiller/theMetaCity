from flask import abort, render_template
from flask.typing import ResponseReturnValue

from tmc.extensions import read_session
from tmc.queries import media as media_queries

from .bp import bp as audio


@audio.route("/")
def all() -> ResponseReturnValue:
    audios = media_queries.all_audio(read_session())
    return render_template("media/audio/all.jinja2", audios=audios)


@audio.route("/<int:id>/")
def single(id) -> ResponseReturnValue:
    item = media_queries.audio_by_id(read_session(), id)
    if item is None:
        abort(404)
    return render_template("media/audio/single.jinja2", audio=item)
