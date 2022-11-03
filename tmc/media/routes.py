from flask import render_template, abort, make_response
from tmc import db, cache
from tmc.media import media
from tmc.models import Video, Audio, Code, Picture, MediaItem, Tags


@media.route('/')
def home():
    all_media = []
    all_media += Video.query.all()
    all_media += Audio.query.all()
    all_media += Picture.query.all()
    all_media += Code.query.all()
    all_media.sort(key=lambda media_entry: media_entry.parent_id)
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


@media.route('/code/')
def show_all_code():
    code_snippets = Code.query.order_by(Code.parent_id.desc()).all()
    return render_template('index.jinja2', media=code_snippets)


@media.route('/code/<code_id>')
def show_specific_code(code_id):
    if code_id.isnumeric():
        code_snippet = Code.query.filter_by(id=code_id).first_or_404()
        return render_template('detailed/code.jinja2', code_snippet=code_snippet)
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


@media.route('/picture/')
def show_all_pictures():
    pictures = Picture.query.order_by(Picture.parent_id.desc()).all()
    return render_template('index.jinja2', media=pictures)


@media.route('/picture/<picture_id>')
def show_specific_picture(picture_id):
    if picture_id.isnumeric():
        picture = Picture.query.filter_by(id=picture_id).first_or_404()
        return render_template('detailed/picture.jinja2', picture=picture)
    else:
        abort(404)


@media.route('/tag/<tag>')
def show_specific_tag(tag):
    tag_media = []
    tag_media += db.session.query(Video).join(MediaItem, Video.Parent).filter(MediaItem.tags.any(Tags.tag == tag))
    tag_media += db.session.query(Audio).join(MediaItem, Audio.Parent).filter(MediaItem.tags.any(Tags.tag == tag))
    tag_media += db.session.query(Picture).join(MediaItem, Picture.Parent).filter(MediaItem.tags.any(Tags.tag == tag))
    tag_media += db.session.query(Code).join(MediaItem, Code.Parent).filter(MediaItem.tags.any(Tags.tag == tag))
    tag_media.sort(key=lambda media_entry: media_entry.parent_id)
    tag_media = tag_media[::-1]
    return render_template('tags.jinja2', media=tag_media)


@media.route('/sitemap.xml')
@cache.cached()
def sitemap():
    all_media = []
    all_media += Video.query.all()
    all_media += Audio.query.all()
    all_media += Picture.query.all()
    all_media += Code.query.all()
    template = render_template('sitemap_media.xml', **locals())
    response = make_response(template)
    response.headers['Content-Type'] = 'application/xml'
    return response



@media.errorhandler(404)
def page_not_found(e):
    return render_template('404.html'), 404
