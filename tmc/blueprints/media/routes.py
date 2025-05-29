from flask import render_template, abort, make_response
from tmc import db, cache
from . import media
from tmc.models.media import Audio
from tmc.models.media.video import VideoSelector


@media.route('/')
def home():
    all_media = []
    all_media += Video.query.all()
    all_media += Audio.query.all()
    all_media = all_media[::-1]
    return render_template('index.jinja2', media=all_media)


@media.route('/favicon.ico')
def show_favicon():
    return ''


@media.route('/video/')
def show_all_videos():
    videos = Video.query.order_by(Video.parent_id.desc()).all()
    return render_template('index.jinja2', media=videos)


@media.route('/video/<video_id>/')
def show_specific_video(video_id):
    if video_id.isnumeric():
        video = Video.query.filter_by(id=video_id).first_or_404()
        return render_template('detailed/video.jinja2', video=video)
    else:
        abort(404)



@media.route('/audio/')
def show_all_audio():
    audio = Audio.query.order_by(Audio.parent_id.desc()).all()
    return render_template('index.jinja2', media=audio)


@media.route('/audio/<audio_id>')
def show_specific_audio(audio_id):
    if audio_id.isnumeric():
        audio = Audio.query.filter_by(id=audio_id).first_or_404()
        return render_template('detailed/audio.jinja2', audio=audio)
    else:
        abort(404)



@media.errorhandler(404)
def page_not_found(e):
    return render_template('404.html'), 404
