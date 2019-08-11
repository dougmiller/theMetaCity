from flask import render_template
from tmc import db, cache
from tmc.blog import blog
from tmc.models import Article, Tag


@blog.route('/')
@cache.cached()
def home():
    articles = Article.query.\
        filter_by(type='blog')\
        .order_by(Article.creation_date.desc())\
        .limit(10)\
        .all()
    tags = Tag.query\
        .all()
    return render_template('blog_index.html', **locals())


@blog.route('/archive/')
@cache.cached()
def archive():
    articles = Article.query.\
        filter_by(type='blog')\
        .order_by(Article.creation_date.desc())\
        .all()
    tags = Tag.query\
        .all()
    return render_template('archive.html', **locals())


@blog.route('/<string:url>/')
@cache.cached()
def title(url):
    article = Article.query.\
        filter_by(url=url)\
        .filter_by(type='blog')\
        .first_or_404()
    return render_template('article.html', article=article)


@blog.route('/<int:year>/')
@cache.cached()
def year(year):
    articles = Article.query\
        .filter(db.func.extract('year', Article.creation_date) == year)\
        .filter_by(type='blog')\
        .all()
    return render_template('index.html', articles=articles)


@blog.route('/<int:year>/<string:url>/')
@cache.cached()
def year_and_title(year, url):
    article = Article.query\
        .filter(db.func.extract('year', Article.creation_date) == year)\
        .filter_by(type='blog')\
        .filter_by(url=url).first_or_404()
    return render_template('article.html', article=article)


@blog.route('/<int:year>/<int:month>/')
@cache.cached()
def year_and_month(year, month):
    articles = Article.query\
        .filter(db.func.extract('year', Article.creation_date) == year)\
        .filter(db.func.extract('month', Article.creation_date) == month).all()\
        .filter_by(type='blog')
    return render_template('index.html', articles=articles)


@blog.route('/<int:year>/<int:month>/<string:url>/')
@cache.cached()
def year_and_month_and_title(year, month, url):
    article = Article.query\
        .filter(db.func.extract('year', Article.creation_date) == year)\
        .filter(db.func.extract('month', Article.creation_date) == month)\
        .filter_by(type='blog')\
        .filter_by(url=url).first_or_404()
    return render_template('article.html', article=article)


@blog.route('/tags/')
@cache.cached()
def tags():
    tags = Tag.query.all()
    return render_template('tags.html', tags=tags)


@blog.route('/tags/<string:tag>/')
@cache.cached()
def tags_tag(tag):
    tag = Tag.query\
        .filter_by(tag=tag)\
        .first_or_404()
    return render_template('tag.html', tag=tag)
