from flask import render_template

from tmc.models.media import Audio

from . import audio


@audio.route('/')
def all():
    audios = Audio.all()
    return render_template('media/audio/all.jinja2', audios=audios)


@audio.route('/<int:id>/')
def single(id):
    audio = Audio.get_or_404(id)
    return render_template('media/audio/single.jinja2', audio=audio)
