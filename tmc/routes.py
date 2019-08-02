from flask import render_template, abort
from tmc import tmc, db, cache
from tmc.models import Article, Tag


@tmc.route('/')
@cache.cached()
def index():
    articles = Article.query.order_by(Article.creation_date.desc()).limit(3).all()
    return render_template('front-page.html', articles=articles)


@tmc.route('/about/')
@cache.cached()
def about():
    return render_template('about.html')


@tmc.route('/blog/')
@cache.cached()
def blog():
    articles = Article.query.\
        filter_by(type='blog')\
        .order_by(Article.creation_date.desc())\
        .limit(10)\
        .all()
    tags = Tag.query\
        .all()
    return render_template('blog/index.html', **locals())


@tmc.route('/blog/archive/')
@cache.cached()
def blog_archive():
    articles = Article.query.\
        filter_by(type='blog')\
        .order_by(Article.creation_date.desc())\
        .all()
    return render_template('blog/archive.html', articles=articles)


@tmc.route('/blog/<string:url>/')
@cache.cached()
def blog_with_title(url):
    article = Article.query.\
        filter_by(url=url)\
        .filter_by(type='blog')\
        .first_or_404()
    return render_template('blog/article.html', article=article)


@tmc.route('/blog/<int:year>/')
@cache.cached()
def blog_with_year(year):
    articles = Article.query\
        .filter(db.func.extract('year', Article.creation_date) == year)\
        .filter_by(type='blog')\
        .all()
    return render_template('blog/index.html', articles=articles)


@tmc.route('/blog/<int:year>/<string:url>/')
@cache.cached()
def blog_with_year_and_title(year, url):
    article = Article.query\
        .filter(db.func.extract('year', Article.creation_date) == year)\
        .filter_by(type='blog')\
        .filter_by(url=url).first_or_404()
    return render_template('blog/article.html', article=article)


@tmc.route('/blog/<int:year>/<int:month>/')
@cache.cached()
def blog_with_year_and_month(year, month):
    articles = Article.query\
        .filter(db.func.extract('year', Article.creation_date) == year)\
        .filter(db.func.extract('month', Article.creation_date) == month).all()\
        .filter_by(type='blog')
    return render_template('blog/index.html', articles=articles)


@tmc.route('/blog/<int:year>/<int:month>/<string:url>/')
@cache.cached()
def blog_with_year_and_month_and_title(year, month, url):
    article = Article.query\
        .filter(db.func.extract('year', Article.creation_date) == year)\
        .filter(db.func.extract('month', Article.creation_date) == month)\
        .filter_by(type='blog')\
        .filter_by(url=url).first_or_404()
    return render_template('blog/article.html', article=article)


@tmc.route('/workshop/')
@cache.cached()
def workshop():
    articles = Article.query\
        .filter_by(type='workshop')\
        .order_by(Article.creation_date.desc()).all()
    return render_template('workshop/index.html', articles=articles)


@tmc.route('/workshop/<string:url>/')
@cache.cached()
def workshop_with_title(url):
    article = Article.query\
        .filter_by(type='workshop') \
        .filter_by(url=url).first_or_404()
    return render_template('workshop/article.html', article=article)


@tmc.route('/blog/tags/')
@cache.cached()
def tags():
    tags = Tag.query.all()
    return render_template('blog/tags.html', tags=tags)


@tmc.route('/blog/tags/<string:tag>/')
@cache.cached()
def tags_tag(tag):
    tag = Tag.query\
        .filter_by(tag=tag)\
        .first_or_404()
    return render_template('blog/tag.html', tag=tag)


@tmc.route('/rss/')
@cache.cached()
def rss():
    pass
