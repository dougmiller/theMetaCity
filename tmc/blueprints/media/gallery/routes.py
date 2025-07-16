from flask import render_template, abort, make_response
from tmc import db, cache
from . import gallery
from tmc.models.media import Gallery


@gallery.route('/')
def all():
    galleries = Gallery.all()
    return render_template('index.jinja2', galleries=galleries)


@gallery.route('/<int:id>/')
def single(id):
    gallery = Gallery.get_or_404(id)
    return render_template('detailed/audio.jinja2', gallery=gallery)
