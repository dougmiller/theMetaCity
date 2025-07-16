from flask import render_template, abort, make_response
from tmc import db, cache
from . import media
from tmc.models.media import Asset, Audio, Video


@media.route('/')
def home():
    all = Asset.all()
    return render_template('media/index.jinja2', media=all)


@media.route('/favicon.ico')
def show_favicon():
    return ''


@media.errorhandler(404)
def page_not_found(e):
    return render_template('404.html'), 404


@media.route('/sitemap.xml')
#@cache.cached()
def sitemap():
    media = Asset.all()
    template = render_template('media/sitemap.xml', media=media)
    response = make_response(template)
    response.headers['Content-Type'] = 'application/xml'
    return response
