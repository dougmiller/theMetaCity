from flask import render_template
from tmc import tmc, cache
from tmc.models import Article


@tmc.route('/')
@cache.cached()
def index():
    articles = Article.query.order_by(Article.creation_date.desc()).limit(3).all()
    return render_template('index.html', articles=articles)


@tmc.route('/about/')
@cache.cached()
def about():
    return render_template('about.html')


@tmc.route('/rss/')
@cache.cached()
def rss():
    pass
