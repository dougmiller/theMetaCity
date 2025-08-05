from flask import make_response, render_template

from tmc.extensions import cache
from tmc.models.blog import Article

from . import home


@home.route('/')
#@cache.cached()
def index():
    articles = Article.latest_by_id(3)
    return render_template('home/index.jinja2', articles=articles)


@home.route('/about/')
@cache.cached()
def about():
    return render_template('home/about.jinja2')


@home.route('/rss/')
@cache.cached()
def rss():
    pass


@home.route('/sitemap.xml')
#@cache.cached()
def sitemap():
    template = render_template('home/sitemap.xml', **locals())
    response = make_response(template)
    response.headers['Content-Type'] = 'application/xml'
    return response
