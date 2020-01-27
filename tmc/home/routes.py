from flask import render_template, make_response
from tmc import cache
from tmc.home import home
from tmc.models import Article


@home.route('/')
@cache.cached()
def index():
    articles = Article.query.order_by(Article.creation_date.desc()).limit(3).all()
    return render_template('index.html', articles=articles)


@home.route('/about/')
@cache.cached()
def about():
    return render_template('about.html')


@home.route('/rss/')
@cache.cached()
def rss():
    pass


@home.route('/sitemap.xml')
@cache.cached()
def sitemap():
    template = render_template('sitemap.xml', **locals())
    response = make_response(template)
    response.headers['Content-Type'] = 'application/xml'
    return response
