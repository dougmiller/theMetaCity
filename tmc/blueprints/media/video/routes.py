from flask import render_template

from tmc.models.media import Video

from . import video


@video.route("/")
def all():
    videos = Video.all()
    return render_template("index.jinja2", videos=videos)


@video.route("/<int:id>/")
def single(id):
    video = Video.get_or_404(id)
    return render_template("media/video/single.jinja2", video=video)
