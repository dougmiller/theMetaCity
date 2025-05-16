from flask import render_template, make_response
from tmc.extensions import db, cache
from . import home
from tmc.models.blog import ArticleSelector as Article

@home.route('/')
#@cache.cached()
def index():
    articles = db.session.execute(
        db.select(Article)
          .order_by(Article.created_at.desc())
          .limit(3)
    ).scalars().all()
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
@cache.cached()
def sitemap():
    template = render_template('home/sitemap.xml', **locals())
    response = make_response(template)
    response.headers['Content-Type'] = 'application/xml'
    return response
