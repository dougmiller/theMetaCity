from flask import render_template
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
