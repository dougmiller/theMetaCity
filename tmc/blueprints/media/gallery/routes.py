from flask import abort, render_template
from flask.typing import ResponseReturnValue

from tmc.extensions import read_session
from tmc.queries import media as media_queries

from .bp import bp as gallery


@gallery.route("/")
def all() -> ResponseReturnValue:
    galleries = media_queries.all_gallery(read_session())
    return render_template("index.jinja2", galleries=galleries)


@gallery.route("/<int:id>/")
def single(id) -> ResponseReturnValue:
    item = media_queries.gallery_by_id(read_session(), id)
    if item is None:
        abort(404)
    return render_template("detailed/audio.jinja2", gallery=item)
